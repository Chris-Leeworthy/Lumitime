# Rebuild Lumitime for macOS

> Captured from the Lumitime project on 8 September 2026.

## Prompt

Create a complete, runnable native macOS application called **Lumitime**, packaged as **Lumitime.app**, from an empty directory. Reproduce the current Tamura Lumitime KT-10B tribute described below. Implement and verify it; do not stop at a plan.

Write your own implementation from this specification. Choose your own internal architecture, drawing helpers, and tests. This prompt is self-contained: do not require the original repository, source files, compiled application, or image assets. The requirements describe the intended appearance and behaviour; generate all code and assets yourself.

### Platform and deliverables

- Swift with Cocoa/AppKit, Apple silicon, macOS 13 or newer.
- Compile directly using Apple Command Line Tools and `xcrun swiftc`; no Xcode project, Swift packages, third-party dependencies, server, or runtime network connection is required.
- Produce `Source/main.swift`, `build.sh`, `README.md`, `.gitignore`, `Assets/Icon.png`, `Assets/Lumitime.icns`, `Preview.png`, and the built `Lumitime.app`.
- Use bundle identifier `local.lumitime.desktop`, executable `Lumitime`, bundle name/display name `Lumitime`, bundle version `2`, marketing version `1.0`, and ad-hoc code signing.
- Archived experiments under `work/`, Git history, caches, and an existing compiled app are not inputs to the rebuild.

### Appearance

Reproduce a vintage desktop clock with a broad cream enclosure, almost square upper shoulders, tapered sides, rounded lower corners, dark smoked glass, a cream trapezoidal pedestal, and a dark foot. Put a brown LUMITIME badge on the lower-right case rim. Use subtly shaded native vector paths, a faint diagonal glass reflection, and a charcoal surrounding background.

Use a flipped 800 × 570 design canvas, uniformly scaled and centred within the view. The compact mode uses an 800 × 405 canvas and hides the pedestal while retaining the enclosure. Full screen uses a cropped design canvas `(90,75,655,245)` and shows the illuminated time, flower, AM/PM, and transient colour label against pure black without the enclosure, badge, glass reflection, or pedestal. Preserve aspect ratio when resizing.

Draw narrow, square-ended, segmented digits from polygon paths, not a digital font. Each main digit is 90 × 189 design units with 10-unit strokes, divided verticals and visible dark seams. Horizontal shutters wrap around the left corner. Construct seven separate shutter shapes: top, upper-right, lower-right, bottom, lower-left, upper-left, and middle. The right uprights span y=0–93 and y=96–189 at x=80–90. The left uprights span y=19–93 and y=96–171 at x=0–10. The top bar spans x=0–77 and y=0–10, with a short return down the left corner to y=16. The bottom bar spans x=0–77 and y=179–189, with a short return up the left corner to y=174. The middle bar spans x=13–77 and y=89.5–99.5. Use ordinary seven-segment numeral combinations with these distinctive shutter shapes. The leading hour position contains only the two right-hand segments for a `1`, and is blank for hours 1–9. Main digit origins are `(153,102)`, `(365,102)`, and `(477,102)`; the leading 1 occupies x=124–134, with its two strokes at y=102–195 and y=198–291. The steady colon has two 12 × 7 rectangles at x=290 and y=164/234. Put small AM/PM lettering below the flower, aligned with its left petal extent and the digit baseline.

### Time and animation

Read the current system date on every 30 fps timer update in the main run loop's common modes. Use the current calendar/time zone and a 12-hour display: midnight is 12 AM, noon is 12 PM, minutes always have two digits. Do not accumulate elapsed ticks as the clock's source of truth. This ensures recovery after sleep or system time changes.

The seconds ornament must use the overlap of two vector shapes: a rotating disc clipped by a fixed mask. Do not animate petal lengths or substitute a spinning complete flower.

- Each pattern has 16 skewed, tapered, round-ended spokes at 22.5° intervals, alternating lengths 40/30 and half-widths 3.4/2.1. Tangential root offsets are +4.5 for the disc and −4.5 for the reversed-skew mask, with root half-width 0.35 at y=−2.
- Rotate the fixed reversed-skew mask clockwise by 1°. Rotate the disc using `(unixSeconds remainder 64) × 5.625` degrees. This advances 45° every eight seconds; repeated spoke symmetry produces the bloom/collapse effect, with an approximately four-second visual cadence.
- Multiply all ornament dimensions by 1.4641 and place its visible centre at approximately (645,185.205) in the main design canvas.
- A small outer light travels clockwise once per minute, starting at the top. Its construction radius is 46.46 and its diameter is 5.8443. Clip it through a fixed ring of 30 round apertures, diameter 4.2504, at two-second intervals. The light is visible intermittently as it crosses apertures.
- Derive both rotation phases from Unix time including fractional seconds. The disc makes one revolution in 64 seconds. The orbit light makes one revolution in 60 seconds, reaching the rightmost point at second 15, the bottom at second 30, and the leftmost point at second 45.

### Colours and notices

Provide these three palettes in this order. Values are sRGB components:

| Stored value | Menu label | Illumination RGB | Highlight RGB | Inactive RGBA |
|---|---|---|---|---|
| orange | Original Orange | 1, .22, .045 | 1, .38, .12 | .13, .065, .045, .24 |
| ledRed | LED Red | .88, 0, .035 | 1, .025, .075 | .12, .005, .012, .24 |
| vfdBlueGreen | VFD Blue-Green | .22, 1, .78 | .61, 1, .89 | .035, .13, .10, .24 |

Default to orange. Illuminate the digits, colon, flower, orbit dot, and AM/PM consistently. Active paths have a nine-unit glow at alpha `.65 × brightness` plus a .6-unit highlight stroke at alpha `.5 × brightness`. Dim mode uses brightness .48 instead of 1. Leave inactive segments faintly visible using the palette’s inactive colour.

After selecting or cycling a colour, show its uppercase name for two seconds in custom wide, chamfered vector lettering below the digits at y=306. Design monoline uppercase glyphs on an approximately 6 × 7 unit grid, with angular corners, short diagonal chamfers on rounded letters, and a 9-unit character advance. Scale by 1.65 and draw with a 1.2-unit stroke and bevel joins. Spaces remain blank and the hyphen is a short centred horizontal stroke. Aim for wide 1970s science-fiction lettering. Centre at x=400 in windowed mode and x=417.5 in full screen. Fade over the final .3 seconds. Also issue a medium-priority accessibility announcement of the colour name.

### Window, menus, and persistence

Create an 800 × 570 titled, closable, miniaturizable, resizable window named `Lumitime KT-10B`, with a transparent title bar, minimum size 400 × 310, and frame autosave name `LumitimeWindow`. Allow dragging the view to move the window. Use regular application activation and quit when the last window closes.

App menu: About Lumitime and Quit Lumitime (⌘Q). The About panel identifies this as an independent native tribute, version 1.0, with illuminated shutter digits and a flower seconds display.

View menu:

| Item | Shortcut | Behaviour / preference key |
|---|---|---|
| Keep on Top | ⌘T | Toggle floating/normal window level; `onTop` |
| Display Only | ⌘D | Hide pedestal and use compact canvas; `displayOnly` |
| Dim Display | ⌘B | Toggle brightness 1/.48; `dim` |
| Enter Full Screen | ⌘F | Native full-screen toggle, display on black |
| Display Colour | submenu | Three checked palette options; `displayColour` |
| Cycle Display Colour | ⌘⇧C | Advance through palettes with wraparound |

Persist the four indicated preferences using UserDefaults and synchronize menu checkmarks. Full-screen exit restores the applicable windowed appearance. Expose the clock view as accessible static text with a current formatted time value.

### Icon assets

Create the icon from scratch: a 1024 × 1024 square image with transparent outer corners, a large rounded cream border running approximately from (66,66) to (958,958), a nearly black subtly shaded interior, and a vivid orange sixteen-ray pinwheel flower centred near (512,512). Alternate long and short tapered rays with round tips and tangentially offset roots, leaving a small dark centre. Include one small orange orbit dot near (700,192). The cream border is approximately 28 pixels thick, warm and pale at the top, darker grey-cream at the bottom. There is no text or clock numeral on the icon. Use native/vector rendering to construct this geometric artwork, export PNG, generate the standard macOS iconset sizes, and run `iconutil -c icns`. Set the icon in both the bundle metadata and the running application so it appears in Finder and the Dock.

### Verification and handoff

1. Run `bash build.sh` and verify that it creates the signed app bundle with its icon and Info.plist.
2. Run `Lumitime.app/Contents/MacOS/Lumitime --self-test`. Implement tests covering all 24 hours and 60 minutes at seconds 0, 9, 10, and 59: 5,760 clock cases. Check 12-hour conversion, AM/PM, minute formatting, leading-hour blanking, and preserved seconds. Sample disc rotation at 30 fps across one minute (1,800 samples), checking its 64-second periodicity and angle range. Test the pattern’s 45-degree symmetry, substantial changes in mask overlap between phases, and the orbit light’s clockwise quarter-minute positions. Include checks of the actual opposing-skew mask used for rendering, and visually verify the animation as well.
3. Render `Preview.png` with `--snapshot Preview.png`. The snapshot uses 1000 × 713 pixels and local date 2026-09-05 10:28:06. Existing UserDefaults can affect snapshots, so use default full-brightness, full-case settings when preparing the main preview.
4. Render and visually inspect additional snapshots for `--colour ledRed`, `--colour vfdBlueGreen`, `--colour-notice`, `--full-screen`, and multiple animation phases using `--seconds <number>`. These options accompany `--snapshot <path>`. `--seconds` sets seconds relative to the snapshot minute; flower rotation remains based on the resulting Unix timestamp.
5. Launch the app and exercise resizing, dragging, every shortcut, colour menu checkmarks, transient notices, full-screen entry/exit, and preference persistence. Inspect bloom/collapse and the clockwise masked orbit dot in motion. Check midnight/noon and leading-hour blanking through the time model.
6. Supply the source, build script, assets, preview, app, and concise build/run instructions. Report checks actually performed and any environment limitations without claiming unperformed checks passed. The app is locally signed, not notarized.

### Supporting visual references

These are historical inspirations for the design, available for visual research if accessible. The specification above is sufficient to proceed if a link is unavailable:

- [AITA KT-10B photographs](https://aita.ocnk.net/product/3385).
- [meguri KT-10B photographs](https://meguri1960.theshop.jp/items/95396001).
- [Fran Blanche’s Lumitime video](https://www.youtube.com/watch?v=SVG9veCKogU), especially the first minute for the bloom/collapse and clockwise orbit light.

The overlapping disc/mask shape is a visual reconstruction, not a claim of exact physical mechanism geometry. Describe the application as an independent tribute, not an official Tamura product.

### Build and documentation requirements

Write a build script that runs from its own directory, stops on errors, creates the app bundle’s executable and resources directories, compiles optimized Swift for arm64 macOS 13 with Cocoa linked, copies the icon, writes valid bundle metadata with high-resolution support, and ad-hoc signs the resulting bundle. Keep compiler caches under `.build`. Ignore macOS Finder metadata, compiler caches, and built app bundles in version control.

Write a README explaining how to open or install the app, prerequisites, the build command, all controls, persistence, local system time behaviour, the flower mechanism, available palettes, verification commands, and reference attribution. Clearly describe the local signing status. Include only verification claims supported by checks you actually run.

Completion means a working, visually inspected app with the specified behaviour and generated assets. A written explanation or mockup alone is not sufficient.
