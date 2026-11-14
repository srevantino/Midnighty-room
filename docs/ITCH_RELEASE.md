# itch.io release guide

itch.io costs nothing to publish on. You set your own revenue share (default 10%, can be 0%), and you can charge, accept "pay what you want", or give it away. Payouts go through PayPal or Stripe, so check that your account type works from Malaysia before you set a price.

## 1. Account and page

1. Sign up at itch.io, then **Dashboard > Create new project**.
2. Kind of project: **Downloadable**. Classification: **Games**.
3. Title: **Midnighty Room**. Short description: *A cozy pixel-art room with a focus timer, lofi music and a cat. Keep it open while you work.*
4. Genre: Simulation. Tags: `cozy`, `relaxing`, `lofi`, `pixel-art`, `productivity`, `desktop-pet`, `casual`, `godot`.
5. Cover image: `assets/branding/itch_cover_630x500.png`. Screenshots: the three in `docs/` (add more with F12).
6. Fill in the **AI disclosure** field on the page honestly. Use `docs/AI_DISCLOSURE.md` as the source for the wording.

## 2. Pricing

Suggested starting point: the demo is free, the full game is a low fixed price (around US$3-5) or pay-what-you-want with a US$2 minimum. Change it freely later. Cheap first, then raise it as you add content.

## 3. Uploads

Upload these from `release/`:

| File | Platform tag | Note |
|---|---|---|
| `midnighty-room-windows.zip` | Windows | The full game |
| `midnighty-room-linux.zip` | Linux | The full game |
| `midnighty-room-demo-windows.zip` | Windows | Free demo (levels 1-2, cheaper items only). Make it a separate free project, or a free download on the same page. |

To update later, use the itch app's Upload tab or butler:

```
butler push build/windows/MidnightyRoom.exe YOURNAME/midnighty-room:windows
butler push build/linux/MidnightyRoom.x86_64 YOURNAME/midnighty-room:linux
```

Do not use the demo exe for the paid page.

## 4. Page text (paste into the description)

**Midnighty Room is a little room you keep open while you work.**

Set a focus timer, put on some lofi and let the cat wander. Every session earns moonlight to spend on furniture, wallpaper, lamps and plants. Level up to open the attic and the loft.

- Focus timer with breaks (15, 25, 45 or 60 minutes)
- 16 lofi, ambient, piano, jazz and chiptune tracks, plus 7 ambience layers (rain, fireplace and more)
- Drag-and-drop decorating with 80+ items, colour variants and saved layouts
- Three rooms, daily goals and a focus calendar
- Desktop companion: shrink it to a small always-on-top window, or a see-through timer pill
- Add your own music: drop MP3, OGG or WAV files into the music folder
- Works offline. Your save stays on your computer.

**Controls:** Space starts the timer. D opens Decorate. M opens the music mixer. F10 shrinks it to a small window. All keys can be changed in Settings.

**Made with:** Godot 4. The art and music were generated with code and AI assistance (see the AI disclosure on this page).

## 5. Before you press Publish

- [ ] Run the Windows exe once from a fresh folder (no save file).
- [ ] Windows may show a SmartScreen warning because the exe is not code-signed. Mention it on the page: click **More info > Run anyway**.
- [ ] Set the page to **Draft**, open the preview link, and check the cover, screenshots and download buttons.
- [ ] Publish, then post once in a community that fits (r/cozygames, r/lofi, r/PixelArt).

## 6. Later

Steam stays possible. The one-time fee is US$100, and `docs/STEAM_RELEASE.md` has the steps. An itch.io release is a cheap way to find out whether people want it first.
