#!/usr/bin/env python3
"""
LittleBricks environment and toolchain discovery tool.
Checks local availability of engine, templates, tools, and runtimes without hardcoding.
"""
import os
import platform
import shutil
import subprocess
import sys

def check_command(cmd, args):
    path = shutil.which(cmd)
    if not path:
        return {"found": False, "path": None, "version": None, "exit_code": None, "error": "Not on PATH"}
    try:
        res = subprocess.run([path] + args, capture_output=True, text=True, timeout=5)
        out = (res.stdout + res.stderr).strip()
        first_line = out.splitlines()[0] if out else "Unknown"
        return {"found": True, "path": path, "version": first_line, "exit_code": res.returncode, "error": None}
    except Exception as e:
        return {"found": True, "path": path, "version": None, "exit_code": -1, "error": str(e)}

def find_template_dirs(version_str):
    candidates = []
    # macOS
    candidates.append(os.path.expanduser(f"~/Library/Application Support/Godot/export_templates/{version_str}"))
    # Linux / XDG
    xdg_data = os.environ.get("XDG_DATA_HOME", os.path.expanduser("~/.local/share"))
    candidates.append(os.path.join(xdg_data, "godot", "export_templates", version_str))
    # Windows
    if "APPDATA" in os.environ:
        candidates.append(os.path.join(os.environ["APPDATA"], "Godot", "export_templates", version_str))

    for p in candidates:
        if os.path.isdir(p):
            return p
    return candidates[0]

def check_templates(version_str):
    template_dir = find_template_dirs(version_str)
    if os.path.isdir(template_dir):
        files = os.listdir(template_dir)
        return {
            "found": True,
            "path": template_dir,
            "has_android": ("android_debug.apk" in files or "android_source.zip" in files),
            "has_web": ("web_release.zip" in files or "web_debug.zip" in files),
            "has_macos": ("macos.zip" in files or "macos_template.app" in files),
            "has_windows": ("windows_release_x86_64.exe" in files or "windows_debug_x86_64.exe" in files),
            "has_linux": ("linux_release.x86_64" in files or "linux_debug.x86_64" in files),
            "files_count": len(files)
        }
    return {
        "found": False,
        "path": template_dir,
        "has_android": False,
        "has_web": False,
        "has_macos": False,
        "has_windows": False,
        "has_linux": False,
        "files_count": 0
    }

def main():
    print("=== LittleBricks Toolchain & Capability Audit ===")
    
    # 1. System
    sys_name = platform.system()
    sys_arch = platform.machine()
    print(f"OS: {sys.platform} ({sys_name} {sys_arch})")
    
    # 2. Godot Binary
    godot = check_command("godot", ["--headless", "--version"])
    raw_version = godot.get("version") or ""
    # Extract base version string for template matching (e.g. '4.7.2.stable' from '4.7.2.stable.official.ed1daf0bf')
    version_key = "4.7.2.stable"
    if godot['found'] and raw_version:
        parts = raw_version.split(".")
        if len(parts) >= 3:
            version_key = f"{parts[0]}.{parts[1]}.{parts[2]}"
            if len(parts) >= 4 and parts[3] in ["stable", "rc1", "rc2", "beta", "dev"]:
                version_key = f"{parts[0]}.{parts[1]}.{parts[2]}.{parts[3]}"
    
    print(f"Godot: {'FOUND' if godot['found'] else 'MISSING'} ({godot.get('path')}) - {raw_version} (exit code: {godot.get('exit_code')})")
    
    # 3. Export templates
    templates = check_templates(version_key)
    print(f"Godot Export Templates ({version_key}): {'FOUND' if templates['found'] else 'MISSING'} at {templates['path']}")
    print(f"  Android APKs: {'YES' if templates['has_android'] else 'NO'}")
    print(f"  Web zips:     {'YES' if templates['has_web'] else 'NO'}")
    print(f"  macOS zip:    {'YES' if templates['has_macos'] else 'NO'}")
    
    # 4. Git, Python, Node
    git = check_command("git", ["--version"])
    print(f"Git: {git.get('version')} ({git.get('path')})")
    print(f"Python: {sys.version.split()[0]} ({sys.executable})")
    node = check_command("node", ["--version"])
    print(f"Node: {node.get('version')} ({node.get('path')})")
    
    # 5. Blender
    blender_path = "/Applications/Blender.app/Contents/MacOS/Blender" if sys_name == "Darwin" else shutil.which("blender")
    if blender_path and os.path.exists(blender_path):
        res = subprocess.run([blender_path, "--version"], capture_output=True, text=True)
        first_line = res.stdout.splitlines()[0] if res.stdout else "Blender"
        print(f"Blender: FOUND ({blender_path}) - {first_line}")
    else:
        print("Blender: MISSING")
        
    # 6. Android ADB and Devices
    adb = check_command("adb", ["version"])
    print(f"ADB: {'FOUND' if adb['found'] else 'MISSING'} ({adb.get('path')}) - {adb.get('version')}")
    if adb['found']:
        dev_res = subprocess.run(["adb", "devices"], capture_output=True, text=True)
        dev_lines = [l for l in dev_res.stdout.splitlines()[1:] if l.strip()]
        print(f"  Connected ADB devices: {len(dev_lines)}")
        for d in dev_lines:
            print(f"    - {d}")
            
    # 7. Java / Android SDK (Verifying real JDK compiler with javac)
    javac = check_command("javac", ["-version"])
    if javac['found'] and javac.get("exit_code") == 0:
        print(f"Java Compiler (JDK): FOUND ({javac.get('path')}) - {javac.get('version')}")
    else:
        print("Java Compiler (JDK): MISSING (javac not on PATH; required for Gradle/Android builds)")
        
    android_home = os.environ.get("ANDROID_HOME") or os.environ.get("ANDROID_SDK_ROOT")
    if android_home and os.path.isdir(android_home):
        print(f"Android SDK: FOUND at {android_home}")
    else:
        print(f"Android SDK: MISSING (Checked: {android_home or 'None set'})")
        
    # 8. Summary
    print("\nSummary:")
    core_ready = godot['found'] and templates['found'] and templates['has_web']
    has_jdk = javac['found'] and javac.get('exit_code') == 0
    has_sdk = bool(android_home and os.path.isdir(android_home))
    print(f"Core Godot Development & Export Pipeline: {'READY' if core_ready else 'NOT READY'}")
    print(f"Detected Engine: {raw_version or 'None'}")
    print(f"Detected Templates: {version_key} at {templates['path']}")
    print(f"Desktop Export: {'READY' if (templates['has_macos'] if sys_name == 'Darwin' else templates['has_linux']) else 'MISSING TEMPLATE'}")
    print(f"Web Export: {'READY' if templates['has_web'] else 'MISSING TEMPLATE'}")
    print(f"Android Toolchain: {'READY' if (templates['has_android'] and has_jdk and has_sdk) else 'BLOCKED (JDK/SDK toolchain required)'}")

    if not core_ready:
        sys.exit(1)
    sys.exit(0)

if __name__ == "__main__":
    main()
