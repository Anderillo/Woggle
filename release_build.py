import json
import platform
import subprocess

# Get Android build numbers
file = open('release_info.json', 'r+')
release_info = json.load(file)
build_name = release_info['android']['build-name']
android_build_number = release_info['android']['build-number'] + 1

# Run Android build
subprocess.run(['flutter', 'build', 'appbundle', '--build-name={}'.format(build_name), '--build-number={}'.format(android_build_number)])
if platform.system() == 'Linux':
    subprocess.Popen(['xdg-open', './build/app/outputs/bundle/release'])
elif platform.system() == 'Darwin':
    subprocess.Popen(['open', './build/app/outputs/bundle/release'])

# Increment Android build number
release_info['android']['build-number'] = android_build_number
file.seek(0)
json.dump(release_info, file, indent=4)
file.truncate()