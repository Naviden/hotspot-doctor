# hotspot-doctor

**Survive working over an unstable iPhone Personal Hotspot.**

A single-file macOS CLI that tells you *why* your tether is bad — not just that it is — and pauses the background processes quietly eating it.

Zero dependencies. Pure Python 3 standard library, on purpose: a tool for a bad connection must never require downloading anything.

```
hotspot  Wi-Fi · Wi-Fi hotspot · gw 172.20.10.1

  phone     ▁▁▁▁▁▁▁▂▁▁▁▁  GOOD
            median     4ms   jitter     3ms   loss   0%   172.20.10.1

  internet  ▃▃▄▃▃×▅▃▄▃▃▃  ROUGH
            median    42ms   jitter    31ms   loss   8%   1.1.1.1

  traffic   ↓  10.0 Kbps   ↑   8.7 Kbps

  Phone link is fine — the cellular side is dropping. Move the phone toward
  a window and force LTE: Settings → Cellular → Cellular Data Options →
  Voice & Data → LTE.

  keep-alive active · 7s · ctrl-c to stop
```

---

## The idea

When a tether goes bad, there are two completely different things that could be broken, and **the fixes are opposites**:

- The **Wi-Fi hop** from your laptop to the phone → move *closer to the phone*.
- The **cellular link** from the phone to the tower → move *the phone* toward a window.

Walking your laptop toward the phone does nothing if the problem is cellular. Moving the phone to a window does nothing if the problem is Wi-Fi range. Without measuring them separately you are just guessing, and half your guesses make things worse.

`hotspot-doctor` pings the hotspot gateway and the open internet on two independent tracks, so it can always tell you which half is broken.

| `phone` | `internet` | Diagnosis | Fix |
|---------|-----------|-----------|-----|
| GOOD | GOOD | Link is healthy | — |
| **BAD** | BAD | The Wi-Fi hop to your phone | Move closer, or plug in USB |
| GOOD | **BAD** | The cellular side | Move the *phone* to a window; force LTE |

---

## Install

```bash
git clone https://github.com/Naviden/hotspot-doctor.git
cd hotspot-doctor && ./install.sh
```

Or just drop the one file anywhere on your `PATH`:

```bash
curl -o ~/.local/bin/hotspot https://raw.githubusercontent.com/Naviden/hotspot-doctor/main/hotspot && chmod +x ~/.local/bin/hotspot
```

Requires macOS and Python 3.8+ (both already on your system — Python 3 ships with the Xcode command line tools).

---

## Commands

| Command | What it does |
|---|---|
| `hotspot watch` | Live latency / jitter / loss monitor, plus keep-alive. The main view. |
| `hotspot doctor` | Diagnose the link and print concrete, ranked fixes |
| `hotspot status` | One-shot snapshot, good for scripts |
| `hotspot calm` | Suspend background bandwidth hogs (**reversible**) |
| `hotspot restore` | Resume everything `calm` suspended |
| `hotspot keepalive [secs]` | Quiet keep-alive only, safe to background |
| `hotspot dns fast` | Point DNS at `1.1.1.1` — carrier DNS is often the real stall |
| `hotspot dns auto` | Hand DNS back to DHCP |

Running `hotspot` with no arguments is the same as `hotspot watch`.

---

## Typical session

```bash
hotspot doctor    # what's wrong, ranked
hotspot calm      # pause the sync hogs
hotspot watch     # leave running in a split pane
```

…and when you're back on real wifi:

```bash
hotspot restore
```

---

## Reading the monitor

- **Two rows, two questions.** `phone` is the Wi-Fi hop to the iPhone. `internet` is the whole path, cellular included.
- **Sparkline** scrolls right, one sample per second, ~46 seconds of history. Bar height is latency; green is fast, yellow mid, red slow. A red `×` is a dropped packet.
- **Verdict:** `GOOD` → `ROUGH` → `BAD` → `DOWN`.
- **Jitter is the number that matters.** High jitter with a low median is what makes a link *feel* broken while speed tests look fine — it's what kills SSH, hot reload, and calls.
- **traffic** shows live throughput. If you're idle and it reads megabits, something is syncing behind your back. Run `hotspot calm`.

---

## About `calm`

`calm` sends `SIGSTOP` to known background sync processes — iCloud Drive (`bird`), background downloads (`nsurlsessiond`), Photos analysis, Google Drive, Dropbox, OneDrive, Adobe Creative Cloud, Spotify. They are **paused, not killed**, and `restore` brings them all back with `SIGCONT`.

Things worth knowing:

- **Nothing syncs while paused.** iCloud Drive and Google Drive are stopped until you `restore`. Spotify playback stops too.
- **Finder may hang** if you browse a Google Drive or Dropbox folder while paused, because their Finder extensions are suspended. `restore` fixes it instantly.
- It deliberately **does not** touch `cloudd` or `photolibraryd`. Suspending those wedges Finder and Photos in ways that are not cleanly reversible.
- App matches are **anchored to `.app` bundle paths**, so a bare process-name match can't accidentally catch a browser tab that merely mentions "Google Drive".
- It **never signals its own process ancestors**, so it cannot freeze the shell you ran it from.
- No `sudo` required. It only signals processes you already own.

To verify nothing is left suspended:

```bash
ps -Ao pid=,state=,comm= | awk '$2 ~ /^T/'
```

Empty output means everything resumed.

---

## What this can't do

It cannot make your cellular signal better. Nothing running on your laptop can. What it can do is stop you wasting bandwidth, stop you idling the link out, and stop you fixing the wrong end.

**And no, an iOS app wouldn't help either.** This started as "can you build an iPhone app to improve my hotspot?" — you can't. iOS sandboxes third-party apps out of the cellular radio and hotspot management entirely, tethered client traffic bypasses on-device `NetworkExtension`/VPN, and apps can't stay alive in the background long enough to babysit a link. The best a real iOS app could do is *measure*. So the useful tool lives on the laptop instead.

---

## The fixes that actually work

Ranked, for when you're at the edge of coverage:

1. **Use USB tethering.** Plug the iPhone into the Mac with a cable. Removes the Wi-Fi hop entirely — no interference, no hotspot sleep, lower latency, and the phone charges. Biggest single win, and it isn't close.
2. **Force LTE instead of 5G.** *Settings → Cellular → Cellular Data Options → Voice & Data → LTE.* At the edge of coverage 5G NSA flaps between bands constantly; LTE is slower on paper and far steadier in practice.
3. **Maximize Compatibility**, if you must stay on Wi-Fi. *Settings → Personal Hotspot.* Forces 2.4 GHz: lower ceiling, much better range.
4. **Low Data Mode** for the network. *System Settings → Wi-Fi → ⓘ → Low Data Mode.* Stops macOS itself doing background fetches over the tether.
5. **`hotspot calm`** for everything else that syncs.

`hotspot doctor` checks which of these apply to you and only shows the relevant ones.

---

## Credits

Built by [Naviden](https://github.com/Naviden) with help from [Claude](https://claude.ai), via [Claude Code](https://claude.com/claude-code).

---

## License

MIT
