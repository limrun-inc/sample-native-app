#!/usr/bin/env python3
"""Run the built UI tests twice with distinct application environments."""
import copy
import pathlib
import plistlib
import sys

products = pathlib.Path(sys.argv[1])
(manifest,) = products.glob("*.xctestrun")
with manifest.open("rb") as source:
    run = plistlib.load(source)
if "TestConfigurations" in run:
    targets = run["TestConfigurations"][0]["TestTargets"]
else:
    targets = [value for key, value in run.items() if key != "__xctestrun_metadata__" and isinstance(value, dict)]
configurations = []
for name in ("First", "Second"):
    configured = copy.deepcopy(targets)
    for target in configured:
        target.setdefault("EnvironmentVariables", {})["LIMRUN_CONFIGURATION"] = name
        target["UITargetAppCommandLineArguments"] = ["--limrun-app-value", "app value with spaces"]
        target["UITargetAppEnvironmentVariables"] = {"LIMRUN_APP_VALUE": name}
    configurations.append({"Name": name, "TestTargets": configured})
with manifest.open("wb") as destination:
    plistlib.dump({"__xctestrun_metadata__": {"FormatVersion": 2}, "TestConfigurations": configurations}, destination)
print(manifest)
