# Hotlines to verify

Every hotline in `app/assets/data/hotlines.json` is marked **"verify before release"**. Only the national
emergency number **911** has a number filled in; every other entry shows **"Number needed"** in the app
until a confirmed number is added. Never ship a guessed emergency number.

## How to verify an entry

1. Get the number from an **official source**: the agency's official website or verified social media page,
   a printed notice at the office or port, or by calling and confirming with staff.
2. Call it once to confirm it is answered by that office (outside an emergency, say you are confirming the number).
3. In `hotlines.json` (or later in the admin panel), fill in `numbers` and set `verification`:
   ```json
   "verification": {"source": "PCG official Facebook page, checked by call", "isPlaceholder": false, "lastVerified": "2026-11-05"}
   ```
4. Tick the box below, note the source and date, then bump `dataVersion` in `meta.json` and run the tests.
   The validator rejects entries marked verified without a date or without a number.

Re-check numbers at least every 90 days; the app warns when a verification is older than that.

## National

| ✓ | Entry | `id` | Number | Source / date |
|---|---|---|---|---|
| ☐ | Emergency 911: National emergency hotline (police, fire, medical) | `national_911` | 911 | |
| ☐ | Philippine Coast Guard: Coast Guard national command center | `pcg_national` | — | |

> 911 is the Philippines' national emergency hotline. Even so, confirm it is still the correct number and
> record the source before release.

## Romblon province

| ✓ | Entry | `id` | Number | Source / date |
|---|---|---|---|---|
| ☐ | Romblon PDRRMO: Provincial disaster risk reduction office | `romblon_pdrrmo` | — | |
| ☐ | Romblon Police Provincial Office: Provincial police | `romblon_ppo` | — | |
| ☐ | Coast Guard Station Romblon: Coast Guard station for Romblon | `pcg_romblon` | — | |

## Ports

### Odiongan Port

| ✓ | Entry | `id` | Number | Source / date |
|---|---|---|---|---|
| ☐ | Odiongan Port help desk | `odiongan_port_helpdesk` | — | |
| ☐ | Coast Guard at Odiongan Port | `odiongan_port_pcg` | — | |

### San Agustin Port

| ✓ | Entry | `id` | Number | Source / date |
|---|---|---|---|---|
| ☐ | San Agustin Port help desk | `san_agustin_port_helpdesk` | — | |
| ☐ | Coast Guard at San Agustin Port | `san_agustin_port_pcg` | — | |

### Romblon Port

| ✓ | Entry | `id` | Number | Source / date |
|---|---|---|---|---|
| ☐ | Romblon Port help desk | `romblon_port_helpdesk` | — | |
| ☐ | Coast Guard at Romblon Port | `romblon_port_pcg` | — | |

### Magdiwang Port

| ✓ | Entry | `id` | Number | Source / date |
|---|---|---|---|---|
| ☐ | Magdiwang Port help desk | `magdiwang_port_helpdesk` | — | |
| ☐ | Coast Guard at Magdiwang Port | `magdiwang_port_pcg` | — | |

### Looc Port

| ✓ | Entry | `id` | Number | Source / date |
|---|---|---|---|---|
| ☐ | Looc Port help desk | `looc_port_helpdesk` | — | |
| ☐ | Coast Guard at Looc Port | `looc_port_pcg` | — | |

### Batangas Port

| ✓ | Entry | `id` | Number | Source / date |
|---|---|---|---|---|
| ☐ | Batangas Port help desk | `batangas_port_helpdesk` | — | |
| ☐ | Coast Guard at Batangas Port | `batangas_port_pcg` | — | |

### Lucena Port (Dalahican)

| ✓ | Entry | `id` | Number | Source / date |
|---|---|---|---|---|
| ☐ | Lucena Port (Dalahican) help desk | `lucena_port_helpdesk` | — | |
| ☐ | Coast Guard at Lucena Port (Dalahican) | `lucena_port_pcg` | — | |

## Towns (MDRRMO and police)

| ✓ | Town | MDRRMO `id` | Police `id` | Numbers | Source / date |
|---|---|---|---|---|---|
| ☐ | Alcantara | `alcantara_mdrrmo` | `alcantara_police` | — | |
| ☐ | Banton | `banton_mdrrmo` | `banton_police` | — | |
| ☐ | Cajidiocan | `cajidiocan_mdrrmo` | `cajidiocan_police` | — | |
| ☐ | Calatrava | `calatrava_mdrrmo` | `calatrava_police` | — | |
| ☐ | Concepcion | `concepcion_mdrrmo` | `concepcion_police` | — | |
| ☐ | Corcuera | `corcuera_mdrrmo` | `corcuera_police` | — | |
| ☐ | Ferrol | `ferrol_mdrrmo` | `ferrol_police` | — | |
| ☐ | Looc | `looc_mdrrmo` | `looc_police` | — | |
| ☐ | Magdiwang | `magdiwang_mdrrmo` | `magdiwang_police` | — | |
| ☐ | Odiongan | `odiongan_mdrrmo` | `odiongan_police` | — | |
| ☐ | Romblon | `romblon_mdrrmo` | `romblon_police` | — | |
| ☐ | San Agustin | `san_agustin_mdrrmo` | `san_agustin_police` | — | |
| ☐ | San Andres | `san_andres_mdrrmo` | `san_andres_police` | — | |
| ☐ | San Fernando | `san_fernando_mdrrmo` | `san_fernando_police` | — | |
| ☐ | San Jose | `san_jose_mdrrmo` | `san_jose_police` | — | |
| ☐ | Santa Fe | `santa_fe_mdrrmo` | `santa_fe_police` | — | |
| ☐ | Santa Maria | `santa_maria_mdrrmo` | `santa_maria_police` | — | |

_Total entries: 53 (1 with a number)._
