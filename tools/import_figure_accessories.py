#!/usr/bin/env python3
"""Convert a reviewed subset of an official LDraw library checkout to game GLBs."""

import argparse
import collections
import hashlib
import json
import math
import pathlib
import re
import struct

PARTS = {
    "vader_helmet": ("30368.dat", 0),
    "trooper_helmet": ("30408p01.dat", 15),
    "iron_helmet": ("10907c01.dat", 320),
    "captain_shield": ("75902p02.dat", 4),
}
IDENTITY = (1, 0, 0, 0, 1, 0, 0, 0, 1)
SOURCE = "https://github.com/kulits/ldraw-parts/tree/c70360d1c588be894997b2168c61909bc8058c4d/ldraw"
FRACTION = 1 / 20
CREASE_LIMIT = math.cos(math.radians(33))


def transform(matrix, point):
    x, y, z = point
    return tuple(matrix[i] * x + matrix[i + 1] * y + matrix[i + 2] * z for i in (0, 3, 6))


def multiply(a, b):
    return tuple(sum(a[row * 3 + k] * b[k * 3 + col] for k in range(3))
                 for row in range(3) for col in range(3))


def mirrored(matrix):
    a, b, c, d, e, f, g, h, i = matrix
    return a * (e * i - h * f) + b * (g * f - d * i) + c * (d * h - g * e) < 0


def add(a, b):
    return tuple(x + y for x, y in zip(a, b))


def sub(a, b):
    return tuple(x - y for x, y in zip(a, b))


def cross(a, b):
    return (a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0])


def dot(a, b):
    return sum(x * y for x, y in zip(a, b))


def unit(vector):
    length = math.sqrt(dot(vector, vector))
    return tuple(x / length for x in vector) if length > 1e-12 else None


def audit(path, content):
    lines = content.decode("utf-8-sig").splitlines()
    license_text = next((line[11:].strip() for line in lines if line.startswith("0 !LICENSE ")), "")
    author = next((line[10:].strip() for line in lines if line.startswith("0 Author: ")), "")
    if not ("CC BY 4.0" in license_text or "CC0" in license_text) or not author:
        raise ValueError(f"{path}: missing author or accepted license: {license_text}")
    return lines, {
        "author": author,
        "license": license_text,
        "sha256": hashlib.sha256(content).hexdigest(),
    }


def expand(library, filename, color, matrix, offset, parity, output, sources):
    path = next(p for p in (library / "parts" / filename, library / "p" / filename) if p.is_file())
    lines, notice = audit(path, path.read_bytes())
    sources[path.relative_to(library).as_posix()] = notice
    ccw = True
    invert_next = False
    for line in lines:
        tokens = line.split()
        if not tokens:
            continue
        match tokens:
            case ["0", "BFC", "INVERTNEXT"]:
                invert_next = True
            case ["0", "BFC", *commands]:
                if "CW" in commands:
                    ccw = False
                if "CCW" in commands:
                    ccw = True
            case ["1", source_color, *values, child]:
                values = list(map(float, values))
                child_offset, child_matrix = values[:3], values[3:]
                expand(library, child.lower().replace("\\", "/"),
                       color if source_color == "16" else int(source_color, 0),
                       multiply(matrix, child_matrix), add(transform(matrix, child_offset), offset),
                       parity ^ invert_next ^ mirrored(child_matrix), output, sources)
                invert_next = False
            case [("3" | "4") as kind, source_color, *values]:
                values = list(map(float, values))
                points = [add(transform(matrix, values[i:i + 3]), offset) for i in range(0, len(values), 3)]
                # Two sign flips retain handedness. Face details remain along -Z.
                points = [(-x * FRACTION, -y * FRACTION, z * FRACTION) for x, y, z in points]
                if parity ^ (not ccw):
                    points.reverse()
                target = output[color if source_color == "16" else int(source_color, 0)]
                target.append(tuple(points[:3]))
                if kind == "4":
                    target.append((points[0], points[2], points[3]))


def read_colors(library):
    colors = {}
    for line in (library / "LDConfig.ldr").read_text(encoding="utf-8-sig").splitlines():
        match = re.match(r"0 !COLOUR (\S+)\s+CODE\s+(\d+)\s+VALUE\s+#([0-9A-Fa-f]{6})", line)
        if match:
            label, code, value = match.groups()
            colors[int(code)] = label, value
    return colors


def linear(component):
    return component / 12.92 if component <= 0.04045 else ((component + 0.055) / 1.055) ** 2.4


def write_glb(path, surfaces, colors):
    payload = bytearray()
    accessors = []
    views = []
    materials = []
    primitives = []
    normals_at = collections.defaultdict(list)

    def coordinate(point):
        return tuple(round(axis, 4) for axis in point)

    for triangles in surfaces.values():
        for a, b, c in triangles:
            normal = unit(cross(sub(b, a), sub(c, a)))
            if normal is not None:
                for point in (a, b, c):
                    normals_at[coordinate(point)].append(normal)

    def attribute(values, with_bounds=False):
        offset = len(payload)
        for value in values:
            payload.extend(struct.pack("<3f", *value))
        view_index = len(views)
        views.append({"buffer": 0, "byteOffset": offset, "byteLength": len(payload) - offset, "target": 34962})
        accessor = {"bufferView": view_index, "componentType": 5126, "count": len(values), "type": "VEC3"}
        if with_bounds:
            accessor["min"] = [min(col) for col in zip(*values)]
            accessor["max"] = [max(col) for col in zip(*values)]
        accessors.append(accessor)
        return len(accessors) - 1

    for code, triangles in sorted(surfaces.items()):
        if code in colors:
            label, value = colors[code]
        elif code >= 0x2000000:
            label, value = f"Direct_{code:07X}", f"{code & 0xFFFFFF:06X}"
        else:
            raise ValueError(f"Unknown LDraw color {code}")
        # Black ABS needs a little reflected detail at tabletop scale.
        if code == 0:
            value = "22252B"
        rgb = [linear(int(value[i:i + 2], 16) / 255) for i in (0, 2, 4)]
        materials.append({"name": label, "doubleSided": True, "pbrMetallicRoughness": {
            "baseColorFactor": [*rgb, 1], "metallicFactor": 0, "roughnessFactor": 0.47,
        }})
        vertices = []
        normals = []
        for a, b, c in triangles:
            face_normal = unit(cross(sub(b, a), sub(c, a)))
            if face_normal is None:
                continue
            for point in (a, b, c):
                neighbors = [n for n in normals_at[coordinate(point)] if dot(face_normal, n) >= CREASE_LIMIT]
                smooth = unit(tuple(sum(axis) for axis in zip(*neighbors)))
                vertices.append(point)
                normals.append(smooth or face_normal)
        if vertices:
            primitives.append({"attributes": {"POSITION": attribute(vertices, True), "NORMAL": attribute(normals)},
                               "material": len(materials) - 1})
    model = {"asset": {"version": "2.0", "generator": "LittleBricks LDraw accessory import"},
             "scene": 0, "scenes": [{"nodes": [0]}], "nodes": [{"name": path.stem, "mesh": 0}],
             "meshes": [{"primitives": primitives}], "materials": materials, "bufferViews": views,
             "accessors": accessors, "buffers": [{"byteLength": len(payload)}]}
    data = json.dumps(model, separators=(",", ":")).encode()
    data += b" " * (-len(data) % 4)
    size = 12 + 8 + len(data) + 8 + len(payload)
    path.write_bytes(struct.pack("<4sII", b"glTF", 2, size) +
                     struct.pack("<I4s", len(data), b"JSON") + data +
                     struct.pack("<I4s", len(payload), b"BIN\0") + payload)
    return {"triangles": sum(accessors[p["attributes"]["POSITION"]]["count"] // 3 for p in primitives),
            "sha256": hashlib.sha256(path.read_bytes()).hexdigest(),
            "bounds": [[fn(accessors[p["attributes"]["POSITION"]][key][axis] for p in primitives)
                        for axis in range(3)] for fn, key in ((min, "min"), (max, "max"))]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("library", type=pathlib.Path, help="Path to the LDraw directory containing parts, p, and LDConfig.ldr")
    parser.add_argument("destination", type=pathlib.Path)
    args = parser.parse_args()
    args.destination.mkdir(exist_ok=True, parents=True)
    colors = read_colors(args.library)
    manifest = {"upstream_mirror": SOURCE, "official_library": "https://library.ldraw.org/",
                "conversion": "Recursive surface expansion and BFC winding, 20 LDU per stud, -X/-Y conversion, soft normals; control lines omitted.",
                "assets": {}}
    for name, (filename, color) in PARTS.items():
        triangles = collections.defaultdict(list)
        sources = {}
        expand(args.library, filename, color, IDENTITY, (0, 0, 0), False, triangles, sources)
        glb = args.destination / f"{name}.glb"
        metadata = write_glb(glb, triangles, colors)
        manifest["assets"][glb.name] = {"root": filename, **metadata, "dependencies": dict(sorted(sources.items()))}
        print(glb.name, metadata["triangles"], metadata["bounds"])
    (args.destination / "sources.json").write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
