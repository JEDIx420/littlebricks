#!/usr/bin/env python3
"""Bake pinned LDraw parts and their licensed dependencies to Godot OBJ meshes."""

import argparse
import concurrent.futures
import hashlib
import json
from pathlib import Path
import re
import urllib.error
import urllib.request

REVISION = "ddf19df14b52729201c6777a84f2835518224786"
MIRROR = f"https://raw.githubusercontent.com/erik-larsen/ldraw/{REVISION}"
ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "game/assets/sourced/ldraw"
LEDGER = ROOT / "game/assets/provenance.json"
IDENTITY = ((1.0, 0.0, 0.0), (0.0, 1.0, 0.0), (0.0, 0.0, 1.0))
PARTS = {
    "galaxy_canopy_4x10": ("2507", 0),
    "galaxy_wing_left_2x3": ("43723a", 0),
    "galaxy_wing_right_2x3": ("43722a", 0),
    "galaxy_engine_cone_4x4": ("3943b", 0),
    "galaxy_sensor_dish_4x4": ("3960", 0),
    "heroes_round_shield": ("75902", 0),
    "heroes_recon_binoculars": ("30162", 0),
    "heroes_reactor_dish_2x2": ("4740", 0),
    "castle_turret_4x8": ("6066", 1),
    "castle_log_brick_1x2": ("30136", 1),
    "castle_window_1x2": ("30044", 1),
    "castle_spindled_fence_1x4": ("30055", 1),
    "castle_triangular_shield": ("3846", 0),
    "castle_shortsword": ("3847", 1),
    "castle_longbow": ("4499", 1),
}


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def reference_name(value):
    name = value.lower().replace("\\", "/")
    if not re.fullmatch(r"(?:(?:s|48|8)/)?[a-z0-9~_.-]+\.dat", name) or ".." in name:
        raise ValueError(f"Unsupported LDraw reference: {value}")
    return name


def subfiles(source):
    for line in source.splitlines():
        fields = line.strip().split(maxsplit=14)
        if fields and fields[0] == "1" and len(fields) == 15:
            yield reference_name(fields[-1])


def candidates(name):
    if name.startswith("s/"):
        return (f"parts/{name}",)
    if name.startswith(("48/", "8/")):
        return (f"p/{name}",)
    if re.fullmatch(r"\d+[a-z]*\.dat", name):
        return (f"parts/{name}", f"p/{name}")
    return (f"p/{name}", f"parts/{name}")


def download(path, cache):
    local = cache / path
    if not local.exists():
        url = f"{MIRROR}/{path}"
        for attempt in range(3):
            try:
                with urllib.request.urlopen(url, timeout=9) as response:
                    raw = response.read()
                local.parent.mkdir(parents=True, exist_ok=True)
                local.write_bytes(raw)
                break
            except urllib.error.HTTPError as error:
                if error.code == 404:
                    return None
                if attempt == 2:
                    raise
            except (urllib.error.URLError, TimeoutError):
                if attempt == 2:
                    raise
    raw = local.read_bytes()
    source = raw.decode("latin-1")
    headers = source.splitlines()
    license_line = next((line for line in headers if line.startswith("0 !LICENSE ")), "")
    if "CC BY 4.0" in license_line:
        license_id = "CC-BY-4.0"
    elif "CC0" in license_line:
        license_id = "CC0-1.0"
    else:
        raise ValueError(f"{path} has an unsupported or absent license: {license_line}")
    author = next((line.removeprefix("0 Author: ").strip() for line in headers if line.startswith("0 Author: ")), "")
    if not author:
        raise ValueError(f"{path} lacks a named author")
    attribution = {"file": path, "author": author, "license": license_id, "sha256": sha256(raw)}
    contributors = {
        match.group(1)
        for line in headers
        if (match := re.match(r"0 !HISTORY \d{4}-\d{2}-\d{2} \[([^]]+)\]", line))
        and match.group(1) != "PTadmin"
    }
    if contributors:
        attribution["history_contributors"] = sorted(contributors)
    return source, attribution


def fetch_name(name, cache):
    for path in candidates(name):
        result = download(path, cache)
        if result is not None:
            return name, result
    raise FileNotFoundError(name)


def fetch_tree(roots, cache):
    assets = {}
    errors = {}
    frontier = set(roots)
    with concurrent.futures.ThreadPoolExecutor(max_workers=24) as pool:
        while frontier:
            next_names = set()
            jobs = {pool.submit(fetch_name, name, cache): name for name in sorted(frontier)}
            for task in concurrent.futures.as_completed(jobs):
                try:
                    name, result = task.result()
                except (FileNotFoundError, ValueError, urllib.error.URLError) as error:
                    errors[jobs[task]] = error
                    continue
                assets[name] = result
                next_names.update(subfiles(result[0]))
            frontier = next_names.difference(assets, errors)
    return assets, errors


def matrix_vector(matrix, vector):
    return tuple(sum(a * b for a, b in zip(row, vector)) for row in matrix)


def matrix_product(matrix, rhs):
    columns = tuple(zip(*rhs))
    return tuple(matrix_vector(columns, row) for row in matrix)


def vector_add(lhs, rhs):
    return tuple(a + b for a, b in zip(lhs, rhs))


def determinant(matrix):
    (a, b, c), (d, e, f), (g, h, i) = matrix
    return a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g)


def faces(name, assets, errors, dependencies, matrix=IDENTITY, offset=(0, 0, 0), inverted=False):
    if name in errors:
        raise ValueError(f"{name}: {errors[name]}")
    source, metadata = assets[name]
    dependencies[name] = metadata
    clockwise = False
    invert_next = False
    for line in source.splitlines():
        fields = line.strip().split(maxsplit=14)
        if not fields:
            continue
        opcode = fields[0]
        if opcode == "0" and fields[1:2] == ["BFC"]:
            if "CW" in fields:
                clockwise = True
            elif "CCW" in fields:
                clockwise = False
            if "INVERTNEXT" in fields:
                invert_next = True
        elif opcode == "1":
            position = tuple(float(value) for value in fields[2:5])
            values = [float(value) for value in fields[5:14]]
            transform = tuple(tuple(values[start:start + 3]) for start in (0, 3, 6))
            child = reference_name(fields[-1])
            yield from faces(
                child, assets, errors, dependencies,
                matrix_product(matrix, transform),
                vector_add(offset, matrix_vector(matrix, position)),
                inverted ^ invert_next,
            )
            invert_next = False
        elif opcode in ("3", "4"):
            values = [float(value) for value in fields[2:]]
            vertices = [
                vector_add(offset, matrix_vector(matrix, values[start:start + 3]))
                for start in range(0, len(values), 3)
            ]
            if clockwise ^ inverted ^ (determinant(matrix) < 0):
                vertices.reverse()
            yield vertices


def oriented(vertex, yaw):
    x, y, z = vertex
    x, y, z = x / 20.0, -y / 20.0, -z / 20.0
    for _ in range(yaw):
        x, z = -z, x
    return x, y, z


def bake(part, number, yaw, assets, errors):
    dependencies = {}
    polygons = [
        [oriented(vertex, yaw) for vertex in polygon]
        for polygon in faces(f"{number}.dat", assets, errors, dependencies)
    ]
    bounds = list(zip(*(vertex for polygon in polygons for vertex in polygon)))
    low, high = [min(axis) for axis in bounds], [max(axis) for axis in bounds]
    shift = (-(low[0] + high[0]) / 2.0, -low[1], -(low[2] + high[2]) / 2.0)
    vertices, triangles = {}, []
    for polygon in polygons:
        indices = []
        for vertex in polygon:
            point = tuple(round(value, 6) for value in vector_add(vertex, shift))
            indices.append(vertices.setdefault(point, len(vertices) + 1))
        for index in range(1, len(indices) - 1):
            face = (indices[0], indices[index], indices[index + 1])
            if len(set(face)) == 3:
                triangles.append(face)
    if not triangles:
        raise ValueError(f"{part}: no mesh triangles")
    author = dependencies[f"{number}.dat"]["author"]
    header = [
        f"# LDraw {number}.dat — {author}",
        "# Converted with tools/import_ldraw_packs.py",
        "# See game/assets/provenance.json for upstream and dependency attribution.",
        f"o {part}",
    ]
    lines = header + ["v %.6f %.6f %.6f" % vertex for vertex in vertices]
    lines += ["f %d %d %d" % face for face in triangles]
    content = ("\n".join(lines) + "\n").encode("utf-8")
    path = OUTPUT / f"{part}_{number}.obj"
    path.write_bytes(content)
    asset = {
        "file": str(path.relative_to(ROOT / "game")),
        "package": "ldraw_official_library",
        "license": "CC-BY-4.0" if any(dep["license"] == "CC-BY-4.0" for dep in dependencies.values()) else "CC0-1.0",
        "upstream_url": f"{MIRROR}/parts/{number}.dat",
        "sha256": sha256(content),
        "size_bytes": len(content),
        "attribution": author,
        "conversion": "Resolved subparts, triangulated, converted to stud units, and normalized pivot",
        "ldraw_dependencies": sorted(dependencies.values(), key=lambda info: info["file"]),
    }
    dimensions = [round(b - a, 4) for a, b in zip(low, high)]
    return asset, dimensions


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--cache", type=Path, required=True)
    args = parser.parse_args()
    assets, errors = fetch_tree({f"{number}.dat" for number, _ in PARTS.values()}, args.cache)
    entries = []
    for part, (number, yaw) in PARTS.items():
        asset, dimensions = bake(part, number, yaw, assets, errors)
        print(part, dimensions, asset["attribution"])
        entries.append(asset)
    ledger = json.loads(LEDGER.read_text())
    generated_files = {item["file"] for item in entries}
    current_assets = [entry for entry in ledger["assets"] if entry["file"] not in generated_files]
    ledger["assets"] = current_assets + entries
    ledger["total_assets"] = len(ledger["assets"])
    ledger["last_updated"] = "2026-11-12"
    LEDGER.write_text(json.dumps(ledger, indent=2, ensure_ascii=False) + "\n")


if __name__ == "__main__":
    main()
