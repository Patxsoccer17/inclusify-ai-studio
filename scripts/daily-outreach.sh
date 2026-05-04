#!/usr/bin/env bash
# Runs every morning at 8am via cron.
# Searches LinkedIn for 10 new outreach contacts and logs them into the Notion Outreach CRM.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/../logs"
LOG_FILE="$LOG_DIR/outreach-$(date +%Y-%m-%d).log"

mkdir -p "$LOG_DIR"

echo "=== Daily Outreach Run: $(date) ===" | tee -a "$LOG_FILE"

claude --dangerously-skip-permissions -p "$(cat <<'PROMPT'
You are running the daily LinkedIn outreach research routine for Inclusify Studio.

## Task
Search LinkedIn for exactly 10 NEW outreach contacts and add each to the Notion Outreach CRM.

---

## Step 1 — Search LinkedIn for contacts

Use WebSearch to find LinkedIn profiles. Run multiple searches to find 10 candidates. Use queries like:
- site:linkedin.com/in "head of talent" "influencer marketing" agency 5-50 employees
- site:linkedin.com/in "VP partnerships" "influencer marketing" agency
- site:linkedin.com/in "founder" "influencer marketing agency"
- site:linkedin.com/in "influencer marketing manager" ("food and beverage" OR "apparel" OR "lifestyle" OR "fitness" OR "gaming" OR "home goods")
- site:linkedin.com/in "brand partnerships lead" consumer brand
- site:linkedin.com/in "head of social" OR "influencer lead" "PR agency" 10-100 employees
- site:linkedin.com/in "founder" "PR agency" influencer

Target contact types (in priority order):
1. Heads of Talent, VP of Partnerships, or Founders at influencer marketing agencies with 5–50 employees → Lead Type: Agency, Notes: Prompt 1
2. Influencer Marketing Managers or Brand Partnership Leads at consumer brands in food & beverage, apparel, lifestyle, fitness, gaming, or home goods → Lead Type: Brand, Notes: Prompt 2
3. Founders, Heads of Social, or Influencer Leads at PR agencies with 10–100 employees → Lead Type: PR Agency, Notes: Prompt 3

EXCLUDE: Fortune 500 companies, WPP, IPG, Publicis, Omnicom, Havas, Dentsu (or any subsidiaries), hearing tech brands, accessibility brands, and medical/healthcare brands.

For each candidate collect:
- Full Name
- Company
- Job Title
- LinkedIn URL (full URL, e.g. https://www.linkedin.com/in/username)
- Lead Type (Agency / Brand / PR Agency)
- Which prompt to use (Prompt 1, Prompt 2, or Prompt 3)

---

## Step 2 — Check Notion CRM for duplicates

Query the Notion Outreach CRM database at page ID: 2e89c88af9ee8083bb18e9e74edb5d34
Use notion-search or notion-query-database-view to retrieve existing contacts.
For each candidate you found, check whether their full name OR LinkedIn URL already exists.
Skip any duplicates. Stop once you have exactly 10 non-duplicate contacts.

---

## Step 3 — Add each new contact to Notion

For each of the 10 new contacts, create a new page in the Outreach CRM database with these properties:

| Property         | Value                                   |
|------------------|-----------------------------------------|
| Lead Name        | [Full Name]                             |
| Company          | [Company]                               |
| Role / Title     | [Job Title]                             |
| LinkedIn Profile | [LinkedIn URL]                          |
| Lead Type        | Agency / Brand / PR Agency              |
| Outreach Status  | Not Contacted                           |
| Outreach Channel | LinkedIn                                |
| Service Pitched  | Influencer Marketing                    |
| Notes            | Prompt 1 / Prompt 2 / Prompt 3          |

---

## Step 4 — Report

After all 10 contacts are added, print a summary table like this:

| # | Name | Company | Title | Lead Type | Notes |
|---|------|---------|-------|-----------|-------|
| 1 | ...  | ...     | ...   | ...       | ...   |

Then print: "Daily outreach run complete. 10 new contacts added to Notion CRM."
PROMPT
)" 2>&1 | tee -a "$LOG_FILE"

echo "=== Run finished: $(date) ===" | tee -a "$LOG_FILE"
