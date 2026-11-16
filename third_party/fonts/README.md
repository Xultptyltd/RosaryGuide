# Bundled fonts

Instrument Sans and Newsreader are licensed under the SIL Open Font License 1.1.
See `OFL-InstrumentSans.txt` and `OFL-Newsreader.txt`.

Sources (same files as the iOS app, then instanced to static fonts for Android):

- Instrument Sans: Copyright 2022 The Instrument Sans Project Authors
  https://github.com/Instrument/instrument-sans
- Newsreader: Copyright 2020 The Newsreader Project Authors
  http://github.com/productiontype/Newsreader

The iOS app ships variable TTFs. These static instances were generated with
fontTools for reliable API 26+ rendering:

- Instrument Sans Regular (wght 400) and Medium (wght 500)
- Newsreader Regular and Italic at opsz 16 (body)
- Newsreader Regular at opsz 28 (titles / display)
