#!/usr/bin/env python3
"""Configure Android release signing for Codemagic builds."""
import os, sys

build_dir = os.environ.get('CM_BUILD_DIR', os.getcwd())
app_dir = os.path.join(build_dir, 'android', 'app')

# Write key.properties
key_props = os.path.join(build_dir, 'android', 'key.properties')
keystore_path = os.path.join(app_dir, 'release-keystore.jks')
with open(key_props, 'w') as f:
    f.write(f"storePassword={os.environ.get('CM_KEYSTORE_PASSWORD', '')}\n")
    f.write(f"keyPassword={os.environ.get('CM_KEY_PASSWORD', '')}\n")
    f.write(f"keyAlias={os.environ.get('CM_KEY_ALIAS', 'audley')}\n")
    f.write(f"storeFile={keystore_path}\n")
print(f"key.properties written to {key_props}")

# Find build.gradle
kts = os.path.join(app_dir, 'build.gradle.kts')
gradle = os.path.join(app_dir, 'build.gradle')

if os.path.exists(kts):
    target = kts
    with open(target, 'r') as f:
        content = f.read()
    if 'signingConfigs' not in content:
        signing = f'''
    signingConfigs {{
        create("release") {{
            val keystoreProperties = java.util.Properties()
            val keystoreFile = file("{key_props}")
            if (keystoreFile.exists()) {{
                keystoreProperties.load(java.io.FileInputStream(keystoreFile))
            }}
            storeFile = file(keystoreProperties.getProperty("storeFile", ""))
            storePassword = keystoreProperties.getProperty("storePassword", "")
            keyAlias = keystoreProperties.getProperty("keyAlias", "")
            keyPassword = keystoreProperties.getProperty("keyPassword", "")
        }}
    }}
'''
        content = content.replace('buildTypes {', signing + '\n    buildTypes {')
        content = content.replace(
            'signingConfig = signingConfigs.getByName("debug")',
            'signingConfig = signingConfigs.getByName("release")'
        )
        with open(target, 'w') as f:
            f.write(content)
        print(f"PATCHED: {target} with release signing config")
    else:
        print("signingConfigs already present")

elif os.path.exists(gradle):
    target = gradle
    with open(target, 'r') as f:
        content = f.read()
    if 'signingConfigs' not in content:
        signing = f'''
    signingConfigs {{
        release {{
            def keystoreProperties = new Properties()
            def keystoreFile = file("{key_props}")
            if (keystoreFile.exists()) {{
                keystoreProperties.load(new FileInputStream(keystoreFile))
            }}
            storeFile file(keystoreProperties['storeFile'])
            storePassword keystoreProperties['storePassword']
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
        }}
    }}
'''
        content = content.replace('buildTypes {', signing + '\n    buildTypes {')
        content = content.replace(
            'signingConfig signingConfigs.debug',
            'signingConfig signingConfigs.release'
        )
        with open(target, 'w') as f:
            f.write(content)
        print(f"PATCHED: {target} with release signing config")
    else:
        print("signingConfigs already present")
else:
    print("ERROR: No build.gradle found!")
    sys.exit(1)

# Verify
print("\n=== Verification ===")
print(f"Keystore exists: {os.path.exists(keystore_path)}")
print(f"key.properties exists: {os.path.exists(key_props)}")
with open(target, 'r') as f:
    c = f.read()
print(f"signingConfigs in gradle: {'signingConfigs' in c}")
print(f"release signing: {'release' in c}")
