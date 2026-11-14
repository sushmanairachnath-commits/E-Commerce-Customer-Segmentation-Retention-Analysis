# E-Commerce-Customer-Segmentation-Retention-Analysis

# End-to-End E-Commerce Customer Segmentation & Retention Analysis (Olist)

**Tools Used:** MySQL (CTEs, Window Functions, Views, Relational Joins) • Power BI (Star Schema, DAX, Interactive Reporting)  
**Dataset:** [Brazilian E-Commerce Public Dataset by Olist](https://kaggle.com) (100k+ Orders across 5 Relational Tables)

---

## 1. Executive Summary & Business Problem
E-commerce marketplaces often spend marketing budgets on broad, untargeted discounts rather than focusing on high-value customer cohorts. Using transactional data from **Olist** (spanning **September 2016 – October 2018**), this project segments **93,357 unique customers** into actionable behavioral tiers using **RFM (Recency, Frequency, Monetary)** modeling to answer three business questions:

1. **Where is revenue concentrated?** Which customer segments drive the majority of sales?
2. **Why do high-value buyers lapse?** Is churn driven by shipping delays or product category mix?
3. **Where should marketing invest next?** Which segments and categories offer the highest retention ROI?

### Key Findings at a Glance
* **Severe Repeat-Purchase Bottleneck:** Only **3.00% of customers** (2,801 out of 93,357) placed more than one order, generating just **5.61%** of total revenue.
* **Two Single-Purchase Tiers Drive 55.71% of Revenue:** **Big-Spending Newcomers** (**R$ 4.35M**, 28.21%) and **At Risk High Spenders** (**R$ 4.24M**, 27.50%) account for **R$ 8.59M** of Olist's **R$ 15.42M** total delivered revenue.
* **Category Mix—Not Delivery Delays—Drives High-Spender Churn:** Root-cause analysis disproved the hypothesis that shipping delays caused high-ticket buyers to lapse (`At Risk High Spenders` had a **7.22%** late delivery rate, virtually identical to repeat `Champions` at **7.21%**). Instead, one-time high spenders buy gift/personal categories (`watches_gifts`, `health_beauty`), whereas repeat `Champions` buy replenishment home goods (`bed_bath_table`).

---

## 2. Dashboard Preview

### Page 1: Executive RFM Segmentation & Revenue Overview
![Executive RFM Overview](images/page1_executive_overview.png)

### Page 2: Retention Drivers, Category Mix & Action Plan
![Retention Drivers & Category Mix](images/page2_retention_drivers.png)

---

## 3. Data Architecture & Cleaning Decisions (MySQL)
Rather than analyzing a single flat CSV, five normalized relational tables (`customers`, `orders`, `order_payments`, `order_items`, `products`) were modeled in **MySQL** with composite primary keys and strategic indexes (`sql/01_schema_and_import.sql`).

Data validation (`sql/02_data_validation.sql`) uncovered three critical schema nuances handled before modeling:
1. **Resolving the `customer_unique_id` Schema Trap:** Olist assigns a new `customer_id` to every order (`99,441` IDs), whereas `customer_unique_id` identifies the actual person (`96,096` humans). Grouping by `customer_unique_id` ensured accurate repeat-purchase counts.
2. **Filtering for Realized Revenue:** Only orders with `order_status = 'delivered'` (**96,478 orders**, 97.02%) and positive payment totals were included, excluding canceled, unavailable, and $0 voucher-only anomalies.
3. **Preventing `NTILE(5)` Skew on Frequency:** Because **97%** of buyers had `Frequency = 1`, applying `NTILE(5)` to Frequency would randomly split identical 1-time buyers across scores 1–5. Instead, `NTILE(5)` was applied to continuous **Recency** and **Monetary** distributions, while **Frequency** used explicit business-rule tiers (`1` order vs. `2` orders vs. `3+` orders) inside `vw_customer_rfm` (`sql/03_rfm_segmentation_view.sql`).

---

## 4. RFM Segment Breakdown

| Customer Segment | Customers | % Customers | Avg Recency (Days) | Avg Frequency | Avg Spend (R$) | Total Revenue (R$) | % Revenue |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **Big-Spending Newcomers** | 14,402 | 15.43% | 141 | 1.00 | 302.13 | 4,351,336.27 | 28.21% |
| **At Risk (High Spenders)** | 13,786 | 14.77% | 443 | 1.00 | 307.68 | 4,241,689.18 | 27.50% |
| **Promising / Needs Nurturing** | 18,065 | 19.35% | 269 | 1.00 | 151.62 | 2,739,066.35 | 17.76% |
| **Hibernating / Lost** | 22,567 | 24.17% | 445 | 1.00 | 72.71 | 1,640,804.91 | 10.64% |
| **Recent One-Time Buyers** | 21,736 | 23.28% | 139 | 1.00 | 72.93 | 1,585,207.85 | 10.28% |
| **Champions** | 985 | 1.06% | 138 | 2.18 | 372.97 | 367,379.59 | 2.38% |
| **At Risk (Repeat Buyers)** | 991 | 1.06% | 431 | 2.08 | 293.60 | 290,953.31 | 1.89% |
| **Loyal Customers** | 825 | 0.88% | 233 | 2.07 | 249.73 | 206,024.31 | 1.34% |
| **Total / Overall** | **93,357** | **100.00%** | **286** | **1.03** | **165.19** | **15,422,461.77** | **100.00%** |

---

## 5. Actionable Business Recommendations

1. **Launch a 90-to-120-Day Cross-Sell Flow for `Big-Spending Newcomers` (R$ 4.35M Opportunity)**
   * **Insight:** High-spending newcomers average **141 days** since purchase and primarily buy one-off items (`health_beauty` R$ 470.5K, `watches_gifts` R$ 464.5K).
   * **Action:** Trigger an automated cross-sell campaign at Day 90 offering a targeted voucher on repeatable home categories (`bed_bath_table`, `housewares`)—the #1 category drivers among repeat `Champions`. Converting just **10%** into second-time buyers generates **~R$ 435,000** in incremental revenue.
2. **Deploy a VIP Win-Back Campaign for `At Risk (High Spenders)` (R$ 4.24M at Stake)**
   * **Insight:** **13,786 customers** who spent an average of **R$ 307.68** have been inactive for **443 days**.
   * **Action:** Run a segmented win-back email/retargeting campaign featuring curated bundles in `watches_gifts` and `health_beauty` before permanent churn.
3. **Audit Carrier SLAs for `Promising / Needs Nurturing` (11.35% Late Delivery Rate)**
   * **Insight:** While late deliveries do not explain high-spender churn, `Promising / Needs Nurturing` buyers experienced an **11.35% late delivery rate** and **15.6-day** average transit time—the worst across all segments.
   * **Action:** Audit regional fulfillment bottlenecks (and prioritize high-LTV states like **BA [R$ 187.26 LTV]** and **GO [R$ 176.70 LTV]** alongside volume leader **SP [R$ 5.77M]**) to prevent shipping friction from blocking second-order conversion.
