# Research Data — Eyadati Marketing Document

---

## Topic 1: Impact of Online Booking on No-Show Reduction

### Primary Source
**Kammrath Betancor P, Boehringer D, Jordan J, et al.** (2025) *Efficient patient care in the digital age: impact of online appointment scheduling in a medical practice and a university hospital on the "no-show"-rate.* Frontiers in Digital Health, 7:1567397. doi: 10.3389/fdgth.2025.1567397. PMCID: PMC12081397.

- **Design:** Retrospective two-center study (private ophthalmology practice + university hospital)
- **Duration:** 20 months (Sept 2022 – Apr 2024)
- **Sample:** 16,894 practice appointments + 81,173 hospital appointments

#### Practice Results (direct comparison of online vs. offline booking)

| Metric | Offline Booking | Online Booking | Change |
|---|---|---|---|
| No-show rate | 5.9% (range 4.6–7.6%) | **1.8%** (range 0.8–5.3%) | **−69.5%** (p < 0.0001) |
| Unused appointments | 22.7% | 10.3% | −54.6% (p < 0.0001) |
| Never-booked slots | 8.6% | 1.6% | −81.4% (p < 0.0001) |

- **Correlation:** As OAS adoption increased, unused appointments dropped proportionally — Spearman r = −0.82 (p < 0.0001, R² = 0.87)
- OAS users rescheduled/cancelled more often (29.8% vs. 12.9%, p < 0.0001), but did so **24–48h in advance** — giving clinics time to refill
- Trend continued downward: unused appointments went from 11.8% (Apr 2023) → 6.0% (Apr 2024)

#### Hospital Results

| Metric | Offline Booking | Online Booking |
|---|---|---|
| No-show rate | 11.2% | 14.3% (p < 0.0001, OR 1.16) |

- Online booking in hospitals uses a **request/triage model** (not direct booking) — patients can't cancel/reschedule autonomously
- This proves that **direct self-booking** (as Eyadati uses) is the effective model, not just any "online" system

#### SMS Reminder Impact (Hospital)
- SMS reminders → OR 0.93 for no-show risk
- Correlation: SMS usage increase → no-show decrease (Spearman r = −0.67, p = 0.0013)
- Regular/specialty consultations lowest no-show (OR 0.40)
- Male patients higher risk (OR 1.11); risk decreases with age (OR 0.99)

---

### Supporting Systematic Reviews

| Study | Scope | Key Finding |
|---|---|---|
| **Open Access scheduling systematic review** (2023, Shiraz Univ., 16 studies) | Outpatient clinics across multiple specialties | 62.5% of studies showed **significant** no-show reduction; 25% non-significant reduction; 12.5% no change |
| **Dantas LF et al. (2018)** — *Health Policy* | **105 studies** systematic review — all specialties, all clinic types | Average no-show: **23%**. Predictors: long lead times, previous no-shows, young age, low socioeconomic status, no private insurance, greater distance |
| **Robotham et al.** — systematic review of **26 studies** | Multiple specialties, multiple countries | Patients reminded of appointments **23% more likely to attend** |
| **Zhao P et al. (2017)** — *J Med Internet Res*, systematic review | Web-based medical appointment systems | Dermatology clinic: lower no-show with online scheduling. Audiology clinic: significantly lower no-show with online scheduling |

### Behavioral & AI Interventions

| Study | Intervention | Result |
|---|---|---|
| **Liu J & KC D (2023)** — *Operations Research*, field experiment | SMS "waits framing" nudge (mentioning wait time for next available slot) | **−28.6%** no-shows |
| **AI appointment system (2024)** — *MDPI Healthcare*, 12:21:2161 | AI-based no-show prediction & management | **−50.7%** no-shows |

### Patient Demand Statistics
- **Bitkom survey (Germany, Nov 2022):** 33% already book medical appointments online; 34% considering it; **66% believe all healthcare facilities should offer OAS**; **22% choose practices specifically for OAS**
- **Canada (Paré et al., 2014):** Patients particularly value flexibility, time savings, and automatic reminders

---

## Topic 2: Algeria's Digital Transformation

### SNTN-2030 — National Digital Transformation Strategy

**Official launch:** May 12, 2025
**Authority:** High Commission for Digitalization (HCN) — under Presidency of the Republic
**High Commissioner:** Meriem Benmouloud (minister rank)
**Presidential backing:** President Abdelmadjid Tebboune, personal follow-up
**Strategic vision:** "Digital Algeria 2030"

#### 5 Strategic Axes — 25 Objectives (2025–2030)

##### Axis 1: Basic ICT Infrastructure

| Objective | Target |
|---|---|
| Quality connectivity for all (households & individuals) | **100% access** |
| Connect all public institutions/establishments | **100% connected** |
| National data centers meeting international standards | **5+ data centers** |
| Competitive cloud services for export | Cloud services exported |
| Generalize use of .dz domain | Nationwide adoption |

##### Axis 2: Human Capital

| Objective | Target |
|---|---|
| Active ICT specialists | **500,000 specialists** |
| Reduce ICT brain drain | **−40%** |
| AI talent pipeline | 74 master's programs in AI across 52 universities; 57,000 CS students |

##### Axis 3: Digital Governance

| Objective | Target |
|---|---|
| Complete digitization of public administration internal management | 100% digital |
| Complete digitization of citizen/business administrative procedures | 100% digital |
| Unified national digital identity for every citizen and business | Launched via Dzair portal |

##### Axis 4: Digital Economy

| Objective | Target |
|---|---|
| Digital sector contribution to GDP | **20% of GDP** |
| Digital startups | **100,000 companies** |
| Digital exports | **$500 million USD** |
| Foreign direct investment in digital sector | **$1 billion USD** |
| National digital champions | **50 leaders** |
| Cash elimination | Banned for transactions **>500,000 DA** |
| Electronic payment adoption | Nationwide promotion |

##### Axis 5: Digital Society
- Equitable and inclusive access to digital technologies
- Increased citizen participation via digital tools
- National digital content reflecting Algerian cultural identity

#### Legal & Security Foundations
- **Digital Law** — currently being drafted (HCN + all sectors)
- **National Information Systems Security Strategy 2025–2029** — adopted by National Council for Information Systems Security
- **Cybersecurity:** Data protection, system protection, digital sovereignty

---

### Dzair Digital Services Portal

**Status:** Launched May/June 2026
**Developer:** High Commission for Digitalization (HCN)
**Cost:** Part of SNTN-2030 budget

| Milestone | Date |
|---|---|
| Design & development completed | Early 2026 |
| Pilot phase (7 ministries) | March–April 2026 |
| Pilot participants | 1,700+ citizens |
| Cybersecurity testing | Apr 2026, coordinated with ASSI (Ministry of National Defence) |
| Cabinet greenlight | May 25, 2026 |
| Public launch | May–June 2026 |

**Key features:**
- **52 services at launch** across 7 ministerial sectors
- Sectors: civil status, justice, health, land registry, national solidarity
- **Unified Digital Identity** (co-developed with Interior Ministry)
- **Electronic Wallet** — store documents, re-share without re-requesting
- **Interoperability backbone** — ministries exchange verified data automatically
- Mobile-first: accessible via smartphone, no office visits needed
- Next wave queued: family records, residence certificates

**Architecture:**
1. Citizen-facing front end (web + mobile)
2. Digital identity layer (Ministry of Interior)
3. Interoperability backbone (fiber-connected ministries)

---

### National Data Center Infrastructure

| Facility | Location | Status | Details |
|---|---|---|---|
| **Algerian National Center for Digital Services** | El Mohammadia, Algiers | **Inaugurated July 5, 2026** by President Tebboune | 80% completion as of May 2025 |
| **Blida Data Center** | Blida | **50% completion** (May 2025) | Second national facility |
| **Oran AI Data Center** | Akid Lotfi district, Oran | **Groundbreaking March 16, 2025** — operations expected late 2026 | First AI HPC center; Huawei partnership; GPU clusters for AI training; serves healthcare, industry, cybersecurity, smart cities |
| **IRIES Sovereign Network** | Nationwide | Operational | Government secure routing |

**Oran AI Data Center — key details:**
- First state-owned HPC facility purpose-built for AI workloads
- Latest-gen GPU clusters (Nvidia via Ooredoo partnership + Huawei)
- Target users: researchers, startups, academic institutions, government
- Cooling: advanced liquid cooling for Mediterranean climate (summers >35°C)
- AI market projection: $498.9M (2025) → $1.69B (2030)

---

### Connectivity Infrastructure

| Project | Status | Details |
|---|---|---|
| **400G all-optical backbone** | Deployed early 2025 | Huawei partnership, covers major urban corridors |
| **5G rollout** | Licenses Dec 2025 | Mobilis, Djezzy, Ooredoo — 8 pilot provinces |
| **ORVAL submarine cable** | Operational | Oran–Valencia, **40 Tbps** capacity to Europe |
| **Medusa submarine cable** | Coming 2026 | Additional international bandwidth |
| **Africa-1 submarine cable** | Coming 2026 | Additional international bandwidth |
| **Algérie Télécom startup fund** | Active | **1.5 billion DZD (~$11M)** for AI, cybersecurity, robotics |

---

### National AI Strategy (2024–2030)

| Metric | Target |
|---|---|
| AI contribution to GDP by 2027 | **7%** |
| AI master's programs | 74 across 52 universities |
| Computer science students | 57,000 |
| AI market value 2025 | $498.9M |
| AI market value 2030 (projected) | $1.69B |
| Startup fund | $11M (Algérie Télécom) |

**Key partnerships:**
- **Huawei:** Data center construction, 400G backbone, vocational training (cloud, cybersecurity, AI starting Sept 2025)
- **Nvidia (via Ooredoo Group):** Sovereign AI Cloud — Nvidia Tensor Core GPUs deployed in Ooredoo's MENA data centers including Algeria
- **China-Algeria Digital Cooperation Deal (May 2024)**

### Key Government Digitalization Projects (already live)
- **Online civil status documents** — verify/request online
- **60+ remote administrative procedures** — submit files online (Ministry of Interior platform)
- **Socio-economic indicators mobile app** — population, density, health infrastructure, education
- **Police assistance mobile app** — request intervention
- **Document authentication control app** — verify civil status documents

---

## Topic 3: Eyadati Feature Architecture (For Integration Reference)

*(To be filled with Eyadati's actual feature details — the following is based on the current marketing document)*

### Core Features
1. **Online Self-Booking Portal** — patients book their own slot from live calendar
2. **Local Notifications** — PWA-based, hardware-scheduled, works offline (6h reminder)
3. **"Call to Cancel" Protocol** — replaces digital cancel button with tel: dialer
4. **Three-Strike Accountability System** — automated strike counting, UI lock at 3 strikes
5. **Patient Reliability Score** — Bayesian attendance rate across all doctors
6. **Global Patient Search** — phone-based lookup for reception desk
7. **7-Day Rolling Calendar** — prevents long-term hoarding
8. **QR Code Clinic Access** — no app store, no password, scan to book

### Key Differentiators (vs. generic OAS)
- **Offline-first notifications** (not dependent on 4G/data)
- **Intentional friction for cancellations** (reduces casual cancellations)
- **Strike system with automated enforcement** (no awkward staff confrontations)
- **Cross-doctor reliability registry** (shared memory across all doctors in the network)
- **No hardware, no training, no app download** — QR + PWA
- **Pricing:** 3,500 DA/month (flat subscription)

### ROI Argument
- 3,500 DA/month vs. ~66,000 DA/month lost to no-shows in manual system
- Pays for itself with recovery of **2 empty consultation slots per month**
- **17x ROI** in first month
- Also saves ~2 hours/day of phone triage labor

---

## Source URLs (for citation verification)

| Source | URL |
|---|---|
| Kammrath Betancor et al. (2025) — Full text | https://pmc.ncbi.nlm.nih.gov/articles/PMC12081397/ |
| SNTN-2030 details — L'Express Algérie | https://www.lexpressquotidien.dz/2025/05/14/strategie-nationale-de-transformation-numerique-les-25-objectifs-de-lalgerie-a-lhorizon-2030/ |
| SNTN-2030 official PDF (English) | https://mail.webservices.dz/images/faq/hcn/SNTN-En.pdf |
| SNTN-2030 — Algerie Eco | https://algerie-eco.com/2025/05/12/la-strategie-nationale-de-transformation-numerique-2030-devoilee/ |
| Oran AI Data Center — AlgeriaTech | https://algeriatech.news/algeria-breaks-ground-on-its-first-ai-data-center-in-oran/ |
| Oran AI Data Center — La Patrie News | https://lapatrienews.dz/inaugure-par-sid-ali-zerrouki-oran-se-dote-dun-centre-de-donnees-et-dintelligence-artificielle/ |
| Dzair Services — WeAreTech Africa | https://www.wearetech.africa/en/fils-uk/news/tech/algeria-launches-dzair-services-to-centralize-public-digital-platforms |
| Dzair Services — DZWatch | https://dzwatch.dz/?p=60380 |
| Dzair Services — AlgeriaTech | https://algeriatech.news/dzair-digital-services-portal-launch-52-services-algeria-2026/ |
| Algerian National Center for Digital Services — APS | https://www.aps.dz/en/presidency-news/mr7p4t4o-president-tebboune-inaugurates-algerian-national-center-for-digital-services |
| PM reviews AI strategy + Dzair — iAfrica | https://iafrica.com/algeria-reviews-national-ai-strategy-progress-and-approves-launch-of-dzair-digital-services-portal/ |
| Ministry of Interior e-services | http://services.interieur.gov.dz/en/ |
| Liu & KC (2023) — Operations Research | https://ideas.repec.org/a/inm/oropre/v71y2023i3p1004-1020.html |
| AI no-show system (2024) — MDPI Healthcare | https://www.mdpi.com/2227-9032/12/21/2161 |
| Open Access scheduling systematic review (2023) | https://pure.amsterdamumc.nl/ws/portalfiles/portal/137333452/Evaluation-of-no-show-rate-in-outpatient-clinics-with-open-access-scheduling-system.pdf |
| Web-based vs traditional scheduling (2023) | https://pmc.ncbi.nlm.nih.gov/articles/PMC10199359/ |
| Web-based reservation & no-show (2025) | https://jurnal.ibik.ac.id/index.php/jimkes/article/view/3799 |
| Systematic review no-show rates (Dantas 2018) | Referenced in Kammrath Betancor et al. ref 7 |
| Bitkom survey (Germany 2022) | Referenced in Kammrath Betancor et al. ref 13 |
