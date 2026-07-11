# Real-Time Global Wikipedia Streaming Analytics Engine

A high-performance, multi-stage data pipeline that ingests, parses, and visualizes live global Wikipedia modifications as they happen in real time. This system handles an active throughput of over **1,000+ events per minute** and has successfully scaled to analyze **250,000+ live stream transactions** without UI latency or system memory bottlenecks.

## System Architecture Overview

The platform is split into two asynchronous components to optimize processing speeds and prevent data loss:
1. **The Ingestion Layer (Python):** Connects to the live Wikimedia EventStreams API, captures raw Server-Sent Events (SSE), parses compressed JSON payloads, computes rolling operational traffic statistics, and pipes unstructured strings into local storage.
2. **The Analytics & Interface Layer (R Shiny):** Leverages memory-efficient reactive polling loops to safely read streaming storage snapshots, executes on-the-fly Natural Language Processing (NLP) tokenization, and renders dynamic tracking visualizations.

---

## Tech Stack & Dependencies

* **Languages:** Python 3.x, R (v4.0+)
* **Data Engineering (Python):** `requests`, `json`, `csv`, `time`
* **Analytics Framework (R):** `shiny`, `tidyverse` (`dplyr`, `ggplot2`, `stringr`), `lubridate`, `tidytext`, `shinythemes`

---

## Core Features & Dashboards

* **Live Ingestion Velocity Tracker:** Displays real-time operational scorecards calculating incoming events per minute, total global events analyzed, and automated crawler footprint ratios.
* **Automated Data Filtering:** Features an interactive query sidebar allowing users to type micro-targeted keywords (e.g., "Olympic", "FIFA") to instantly isolate and segment global trends.
* **On-The-Fly Text Mining (NLP):** Utilizes bigram n-gram tokenization and custom lexical stop-word dictionaries to isolate trending global concepts and breaking world events from live page text paths.
* **Dynamic Domain Tracking:** Visualizes cross-border traffic distributions across individual language subdomains (English, Wikidata, Media Commons, etc.) paired with live bar chart text indexes.

---

## Technical Highlights & Engineering Fixes

* **Memory Optimization:** Solved front-end engine rendering freezes over heavy data loads (100k+ rows) by implementing a moving evaluation buffer (`tail()`) for intensive computation tasks while maintaining full integrity for main KPI counters.
* **String Truncation Rules:** Designed layout-safe string clipping (`str_trunc`) to perfectly fit long, unpredictable media file strings and user directory paths into structural plot axes seamlessly.
* **Time-String Parsing Alignment:** Normalized inconsistent API Z-timestamps into unified wall-clock local times, resolving cross-language time-series dropping issues.

---

## 📦 How to Run Locally

1. **Clone the Repository:**
   ```bash
   git clone [https://github.com/AdithyaSubash7/Real-Time-Global-Wikipedia-Streaming-Analytics-Engine.git](https://github.com/AdithyaSubash7/Real-Time-Global-Wikipedia-Streaming-Analytics-Engine.git)
   cd Real-Time-Global-Wikipedia-Streaming-Analytics-Engine

---

2.  **Fire Up the Ingestion Harvester:**
Run the Python engine first to initialize the file structure and connect to the streaming API.

python wiki_harvester.py

3.  **Launch the Shiny Interface:**
Open RStudio, set your working directory to the project folder, and run the application dashboard file.

shiny::runApp()
