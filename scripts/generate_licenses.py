#!/usr/bin/env python3
"""Bundle third-party licences for Settings > Acknowledgements.

Reads the Swift Package Manager pins in Package.resolved, finds each package's
checkout, copies its LICENSE / LICENSE.txt / COPYING file verbatim, and writes
RosaryGuide/Data/Licenses.json (sorted by name, case-insensitive).

Nothing is fetched online. Resolve packages first (any Xcode build does this),
then run:

    python3 scripts/generate_licenses.py \
        [--checkouts /tmp/RosaryGuide-Derived/SourcePackages/checkouts]

Re-run after adding, removing or updating a package and commit the JSON.
"""
import argparse
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RESOLVED = os.path.join(ROOT, "RosaryGuide.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved")
OUTPUT = os.path.join(ROOT, "RosaryGuide/Data/Licenses.json")
DEFAULT_CHECKOUTS = "/tmp/RosaryGuide-Derived/SourcePackages/checkouts"
LICENSE_NAMES = ["LICENSE", "LICENSE.txt", "LICENSE.md", "LICENCE", "LICENCE.txt", "COPYING", "COPYING.txt"]

# Friendly display names; anything not listed falls back to the repository name.
DISPLAY_NAMES = {
    "abseil-cpp-binary": "Abseil",
    "app-check": "App Check",
    "appauth-ios": "AppAuth",
    "firebase-ios-sdk": "Firebase",
    "google-ads-on-device-conversion-ios-sdk": "Google Ads On-Device Conversion",
    "googleappmeasurement": "GoogleAppMeasurement",
    "googledatatransport": "GoogleDataTransport",
    "googlesignin-ios": "GoogleSignIn",
    "googleutilities": "GoogleUtilities",
    "grpc-binary": "gRPC",
    "gtm-session-fetcher": "GTMSessionFetcher",
    "gtmappauth": "GTMAppAuth",
    "interop-ios-for-google-sdks": "Interop for Google SDKs",
    "leveldb": "LevelDB",
    "lottie-ios": "Lottie",
    "nanopb": "nanopb",
    "promises": "Promises",
    "swift-protobuf": "SwiftProtobuf",
}


def repo_name(location):
    name = location.rstrip("/").rsplit("/", 1)[-1]
    return name[:-4] if name.endswith(".git") else name


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--checkouts", default=DEFAULT_CHECKOUTS)
    args = parser.parse_args()

    with open(RESOLVED) as f:
        pins = json.load(f)["pins"]

    checkouts = {d.lower(): os.path.join(args.checkouts, d) for d in os.listdir(args.checkouts)}
    entries, missing = [], []
    for pin in pins:
        identity = pin["identity"]
        location = pin["location"]
        checkout = checkouts.get(identity.lower()) or checkouts.get(repo_name(location).lower())
        license_path = None
        if checkout:
            for candidate in LICENSE_NAMES:
                path = os.path.join(checkout, candidate)
                if os.path.isfile(path):
                    license_path = path
                    break
        if not license_path:
            missing.append(identity)
            continue
        with open(license_path, encoding="utf-8") as f:
            text = f.read()
        entries.append({
            "id": identity,
            "name": DISPLAY_NAMES.get(identity, repo_name(location)),
            "version": pin["state"].get("version") or pin["state"].get("revision", "")[:7],
            "url": location[:-4] if location.endswith(".git") else location,
            "license": text,
        })

    if missing:
        sys.exit("No checkout or licence file for: " + ", ".join(missing))

    entries.sort(key=lambda e: e["name"].casefold())
    with open(OUTPUT, "w", encoding="utf-8") as f:
        json.dump(entries, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"Wrote {len(entries)} licences to {os.path.relpath(OUTPUT, ROOT)}")
    for e in entries:
        print(f"  {e['name']} {e['version']}")


if __name__ == "__main__":
    main()
