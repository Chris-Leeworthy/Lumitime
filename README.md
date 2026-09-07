# Lumitime for macOS

Open **lumi2.app**. You can also drag it into your Applications folder.

Built for Apple silicon, macOS 13 or newer. This is a locally signed app, not a notarized distribution. No dependencies or network connection are needed to run it.

The clock follows your Mac’s local time in the original 12-hour format. It resynchronizes directly to system time, including after sleep and time-zone changes.

## Controls

Use the **View** menu:

- **⌘T:** Keep on top.
- **⌘D:** Hide the pedestal for a compact display.
- **⌘B:** Dim the orange illumination.
- **⌘F:** Full screen with only the illuminated display on black; exit to restore the case.
- **⌘Q:** Quit.

Drag the window to move it; resize from its edges. Display preferences persist between launches.

## Design

Custom vector segments reproduce the narrow, square-ended orange digits, divided vertical strokes, steady colon, and blank leading hour position. The seconds ornament uses a rigid rotating disc of 16 skewed, tapered, round-ended spokes with tangentially offset roots, alternating long and short, behind a static mask with opposite ray skew, inferred from the blurry mask photograph, rotated clockwise by 1°. Only the overlapping areas are illuminated. The decorative disc rotates 45 degrees every eight seconds. A small outer dot travels clockwise once per minute. Animation runs at 30 frames per second behind smoked glass, with a cream enclosure and pedestal.

Visual references: [AITA KT-10B photographs](https://aita.ocnk.net/product/3385) and [meguri KT-10B photographs](https://meguri1960.theshop.jp/items/95396001).

The animation follows the first minute of [Fran Blanche’s Lumitime video](https://www.youtube.com/watch?v=SVG9veCKogU), including the approximately four-second bloom/collapse and clockwise outer dot. Shape interpolation is a visual reconstruction; its phase is synchronized to system time. This is an independent tribute, not an official Tamura product.

## Build and verification

Source is in `Source/main.swift`. With Apple Command Line Tools installed, run `bash build.sh` from this folder.

Run `lumi2.app/Contents/MacOS/Lumitime --self-test` to check 5,760 time combinations, including midnight, noon, minute formatting, and second boundaries. The app’s native drawing was rendered and visually inspected; `Preview.png` is a fixed-time preview.

The build packages `lumi2.app` with the supplied flower icon in `Assets/Lumitime.icns`, used by Finder and the Dock.
