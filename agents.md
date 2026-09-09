# Block Blaster — AI Development Rules

## Project

This is a Godot Android game called Block Blaster.

## Core principle

The game is OFFLINE-FIRST.

Gameplay must never depend on:

* Internet
* Ads
* Analytics
* External servers

## Development rules

1. Inspect existing code before modifying it.
2. Do not rewrite working systems unnecessarily.
3. Preserve existing gameplay behavior.
4. Make small, safe, testable changes.
5. Do not add dependencies unless genuinely required.
6. Do not add Android permissions unless required.
7. Keep ad functionality isolated inside an AdManager.
8. Ads must never block gameplay.
9. If an ad is unavailable, silently skip it.
10. Never save/cache ad files manually.
11. Let the official ad SDK handle ad caching and expiration.
12. Never show an error to the player just because an ad failed.
13. Never require internet to play Block Blaster.
14. Use async/background operations for ad loading.
15. Do not perform aggressive network polling.
16. Do not show interstitial ads during active gameplay.
17. Rewarded ads must always be user-initiated.
18. Never grant a rewarded-ad reward unless the SDK confirms completion.
19. Check all third-party SDK/plugin behavior.
20. Check every Android permission introduced by plugins.
21. Verify music/audio licenses instead of assuming they are free.
22. Do not fabricate Play Store compliance.
23. Do not fabricate licenses.
24. Follow current Google Play requirements rather than relying on old assumptions.
25. Before modifying important systems, explain the proposed change and inspect dependencies.
26. After modifications, run appropriate validation/build checks.
27. Report remaining risks instead of hiding them.

## Code quality

Prefer:

* modular architecture
* clear naming
* minimal duplication
* centralized configuration
* defensive error handling
* maintainable Godot GDScript
* Android-safe lifecycle handling

Avoid:

* unnecessary abstractions
* unnecessary singletons
* polling loops
* blocking waits
* hardcoded secrets
* hardcoded production ad IDs in development
* large unrelated refactors

## Ad behavior

Preferred flow:

Game starts
→ gameplay available immediately
→ AdManager initializes in background
→ ad loads when possible
→ ad becomes available

At a natural transition:

If valid ad is ready AND cooldown allows it:
show ad
else:
continue normally

Never:

Game
→ wait for internet
→ wait for ad
→ show loading screen
→ continue

## Offline behavior

When internet is unavailable:

Game = WORKS
Music = WORKS
Gameplay = WORKS
Score = WORKS
Settings = WORKS
Ads = OPTIONAL / SKIPPED

Do not display unnecessary "No Internet" errors.

## Testing priority

Always test:

* fresh install
* first launch
* gameplay
* game over
* restart
* pause/resume
* background/foreground
* internet ON
* internet OFF
* internet lost during gameplay
* internet lost during ad loading
* internet restored
* ad available
* ad unavailable
* ad failure
* repeated game overs

## Final response format

After completing work, report:

1. What was inspected
2. What was changed
3. Files changed
4. Tests performed
5. Play Store risks
6. Ad behavior
7. Privacy/Data Safety considerations
8. Music/license considerations
9. Remaining manual tests
10. Any issue that still needs my decision
