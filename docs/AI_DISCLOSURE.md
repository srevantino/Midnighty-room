# AI use: what to disclose, and how not to ship slop

Written November 2026. Not legal advice. Valve changes the wording without notice, so reread the Steamworks Content Survey on the day you submit.

## The short version

1. Do not hide it. The Content Survey answer is an attestation, players can report games, and a game caught with an undisclosed or false AI answer gets far worse treatment than one that was upfront.
2. "AI slop" is a judgement about quality and care, not about a checkbox. The way out is to make the parts players see and hear yours.
3. The single biggest change is replacing the generated art and music with work by people. That also shrinks what you have to disclose.

## What Steam asks

- The Content Survey has a Generative AI section, split into pre-generated content (made during development) and live-generated content (made while the game runs).
- Since the January 2026 rewrite it is about content players consume: art, music, voices, writing, localisation, and also the store page's capsule art, trailers and text.
- Coding assistants are listed as exempt in that rewrite.
- The answer is shown on the store page.
- This game has no live-generated content. It makes no network calls and runs no model.

## Where everything in this game came from

| Part | How it was made | Disclose today? | To change that |
|---|---|---|---|
| Idea, name, direction, what got built and kept | You | No | |
| Game code (GDScript, tools) | Written by an AI model (Claude) at your direction | Code tools are exempt under the January 2026 wording; check the current text | |
| Sprites, icons, logo, app icon | Drawn by Python scripts (`tools/gen_art.py`, `tools/gen_logo.py`) that the AI wrote. No image model was used, but the designs are the AI's | Yes, pre-generated | Commission or draw replacements with the same file names |
| Music, ambience, sound effects | Synthesized by `tools/gen_audio.py`, written by the AI. No audio model was used, but the compositions are the AI's | Yes, pre-generated | License or commission tracks; record or buy ambience |
| In-game text: interface, item names, first-run guide | Written by the AI | Yes, pre-generated | Rewrite it in your own words |
| Store page: capsule art, screenshots, trailer, description | Not made yet | Depends on how you make them | Make them yourself or hire someone |

Whether script-drawn pixel art counts as "generative AI content" is a question of Valve's wording. The cautious and honest reading is yes: an AI decided what every sprite looks like and what every note is.

## Disclosure text you can adapt

If you ship as it stands:

> This game was built by a solo developer with heavy use of an AI coding assistant. The pixel art, music, sound effects and in-game text were produced by code and text the assistant wrote; no image or audio generation models were used. Nothing is generated while you play.

If you replace the art and music first:

> Art by [artist]. Music by [musician]. An AI coding assistant was used during programming. [Add: "Some interface text was drafted with AI and edited by the developer" if that is still true.]

Keep it specific. Vague lines like "AI was used for some assets" are the ones that get picked apart.

## What makes players call something slop, and what to do about each

| Tell | Where this game stands | Fix |
|---|---|---|
| Store capsule and screenshots that look generated | Not made yet | Human-made capsule art. It is the first and often only thing people see |
| Art with no consistent hand | Consistent, but simple and code-drawn | One artist, one style, across every sprite |
| Forgettable or grating music | 16 synthesized loops nobody has listened to critically | Listen to all of them. Delete the weak ones from `TRACKS` in `audio_mixer.gd`. Six good tracks beat sixteen mixed ones. Better: license real lofi |
| Generic writing | Serviceable, written by an AI | Rewrite item names, the guide and the store description in your own voice |
| Bugs and rough edges on day one | 80 automated checks pass; several Windows-only features are untested (see README) | Play it for a week. Get five other people to play it and watch them |
| No sign of a person behind it | Credits list a studio name only | Put your name in the credits. Post devlogs. Answer reviews and forum threads |
| Many near-identical releases from one account | First release | Ship one game and keep updating it |
| Overpriced for what it is | Not priced yet | US$5.99 to US$7.99, with a free demo |

## Before you press publish

- [ ] Every track listened to; weak ones removed
- [ ] Art and music decision made: replace, or ship and disclose plainly
- [ ] In-game text and store description read aloud and rewritten where they sound like nobody
- [ ] Capsule art and trailer made by a person
- [ ] Credits name the people involved (edit `CREDITS` in `scripts/ui/settings_panel.gd`)
- [ ] Content Survey filled in truthfully, matching the table above as it stands on that day
- [ ] The demo has been out long enough to collect feedback, and you acted on it

## Sources

- Steam AI disclosure rules explained (January 2026 rewrite): https://legalmoveslawfirm.com/steam-ai-policy/
- What developers must report: https://www.techbloat.com/steam-ai-disclosure-rules-for-game-developers-what-to-declare.html
- Disclosure share and scope, October 2026: https://finalboss.io/steam-ai-disclosures-hit-49-9-what-buyers-should-check
- Review impact study: https://www.pcgamer.com/software/ai/data-analyst-finds-ai-stigma-on-steam-can-reduce-the-number-of-reviews-a-game-gets-by-around-53-percent-and-the-reviews-it-does-get-are-more-negative/
- False accusations and review bombing: https://www.vice.com/en/article/steam-reviews-have-a-serious-ai-problem-that-needs-to-be-fixed/
