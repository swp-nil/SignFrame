# SignFrame

A Flutter desktop app for annotating sign language videos with frame markers.

> **Note:** This is a personal tool built for my own workflow. It may not be actively maintained or suitable for general use.

## Features

- Browse and open folders of video files
- Play videos with playback speed control
- Set start/end markers to define annotation segments
- Auto-extract gloss names from filenames (`hello_001.mp4` → gloss "hello")
- Track completion status per video
- Save annotations as JSON

## Expected Filename Format

Videos should be named as `gloss_signerId.mp4` where signer ID is numeric:

- `hello_001.mp4` → gloss: `hello` (signer ID: `001`)
- `thank_you_002.mp4` → gloss: `thank_you` (signer ID: `002`)
- `my_file_name.mp4` → gloss: `my_file_name` (no numeric ID, uses full name)
- `wave.mp4` → gloss: `wave`

## Usage

```bash
flutter clean
flutter pub get
flutter run -d windows
```

## Annotation Format

Annotations are saved as `annotations.json` in the selected folder:

```json
[
  {
    "gloss": "hello",
    "instances": [
      {
        "fps": 30.0,
        "frame_start": 10,
        "frame_end": 45,
        "start_ms": 333,
        "end_ms": 1500,
        "instance_id": 1,
        "source": "hello_001.mp4",
        "video_id": "hello_001_001"
      }
    ]
  }
]
```

## License

``` markdown
    Copyright 2026 github.com/swp-nil

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
```

---
Icon can be found here - [Sign language icons created by Freepik - Flaticon](https://www.flaticon.com/free-icons/sign-language)

---
