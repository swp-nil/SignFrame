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

## Usage

```bash
flutter clean
flutter pub get
flutter run -d windows
```

Open a folder containing videos, play a video, set start/end markers, and click "Add Instance" to create annotations.

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
---
Icon can be found here - [Sign language icons created by Freepik - Flaticon](https://www.flaticon.com/free-icons/sign-language)

---


*Why spend 1 hour doing something manually when you can waste 5 hours trying to automate it?*
