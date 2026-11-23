# Feasts group — per-screen spec

IA: `ia-map.md` §5. iOS source: `FeastsView.swift`. Fixture date: 17 November 2026, locale `en-AU`, week starts Monday. iOS refs: `feasts`, `feast-detail`, `feast-related-prayers`, `feast-patronages`, `feast-scripture` (no `feasts-empty` ref). The already-approved Today `week-feast-sheet` is not part of this rewrite and was not recaptured.

Typography and spacing: `docs/parity-v2/feasts-typography.md`.

## Navigation

- Tab root `FeastsView` / `FeastsScreen` inside the Feasts tab. Ambient page wash, large “Feasts” title, `GuideTabBar` with the 90 dp scrim.
- Scope: All feasts / Marian feasts (`GuideChoiceControl` / capsule).
- Week strip (Mon 16–Sun 22 in the ref) with a 36×4 handle that expands to five weeks. Swiping changes `weekOffset`. A “Today” text button appears when the selected day or week is not today.
- `GuideSectionDivider` under the handle, then the agenda. `GuideSectionBoundary` / `SectionBand` between agenda sections. 1 px hairlines, inset 76, between rows in a section.
- Row tap pushes feast detail on the Feasts stack (tab bar stays). The Learn + “Pray this Rosary” row appears only when the first item of the first section is the selected day. The 17 Nov ref has no feast on the selected day, so that row is correctly absent.
- Empty copy: “No upcoming feasts for this selection.”
- There is no search field on the iOS hub; Android no longer has one.
- Feast detail is a push with a local milky chevron-in-chip back (solid white + soft shadow in light, visible 0.16 white disc in dark), inline title, and a width-scaled 330 pt hero (`height = 330 × width/440`) that starts just below the nav with an 8 dp underlap. The nav is a solid `palette.bg` bar plus a 1 px hairline; `navTop` is `max(statusBars, 62.dp)` so the chevron and title are centred at 84 dp, matching the iOS refs. Plain `palette.bg` (not the wash) over the ambient layer. Meaning, at-a-glance, then bands before Keep the day, Prayers for this day, and Scripture and Rosary.
- Related prayers / Patronages / In Scripture exist as iOS views and refs. The current `FeastDetailView` body does not wire `NavigationLink`s to them. Android still ships the three pages (IA + refs) and adds the source `infoRow`s below the fold on detail so they can be opened.
- Debug hooks `-RGDebugOpenFeast` / `RGDebugFeastID` stay iOS-only; Roborazzi opens Presentation of Mary (`presentation-mary`, 21 November, Memorial) directly.

## Per screen

### feasts (hub)

All feasts, week of 16–22 November 2026, today 17 selected with accent-blue fill (not ink). Unselected today would be an accent stroke. Accent 4 dp dots on 21 and 22. Agenda: Next = Presentation of Mary, 21 Nov, Memorial; This week = Our Lord Jesus Christ, King of the Universe, 22 Nov, Solemnity; This month = First Sunday of Advent, 29 Nov, Seasonal.

### feast-detail

Presentation of Mary. Hero art with a 0.18 bottom fade into `palette.bg`. The nav is a solid `palette.bg` bar (not a frost scrim) with the local milky back chip; typo-accurate title and meaning, no Remind me / Pray cards in the first viewport (those `detailActions` exist in source but are unused in the live body and are below the first ref).

### feast-related-prayers

Width-scaled 238 pt hero (`height = 238 × width/440`) starting just below the nav with the same 8 dp underlap and chrome as detail. “Memorial” + serif “Related prayers” + feast short title. Accordion, first prayer expanded on appear (Hail, holy Queen; Memorare; Sub Tuum Præsidium). Flush, no card chrome. English only unless bilingual is on.

### feast-patronages

Same secondary chrome. Intro “Traditions associated with this feast.” Marian default list for Presentation of Mary.

### feast-scripture

Same secondary chrome. Zechariah 2:10-11 and Matthew 12:50 passages with serif title + body.

### feasts-empty

No iOS ref. Android shows the same hub chrome with the empty copy and no agenda rows (test hook). Not a sign-off pair.

## Capture

Roborazzi, Pixel 7, `+night` for every dark stem. Frames: `/workspace/android/shots/v2/android/{stem}-{light,dark}.png`. Sign-off: `/workspace/android/shots/v2/signoff/{stem}.png`. Zooms: `/workspace/android/shots/v2/signoff/zoom/`. Status is `close`, not `matched`, until a Mac Pixel 7 recapture. Not user-approved yet.
