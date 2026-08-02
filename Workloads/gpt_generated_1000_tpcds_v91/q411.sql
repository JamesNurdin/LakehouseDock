-- Goal: Identify item category, brand, state and income‑band combinations where catalog sales net paid is above the overall average, the billing customer also has a web purchase, and exclude any combination that appears in catalog returns. The query uses a CUBE to generate all dimension combinations, a scalar subquery for the average net paid, an EXISTS subquery for web sales, and EXCEPT to subtract return keys.
WITH avg_net_paid AS (
    SELECT AVG(cs.cs_net_paid) AS avg_net_paid
    FROM catalog_sales cs
),
sales_agg AS (
    SELECT 
        i.i_category AS i_category,
        i.i_brand AS i_brand,
        ca.ca_state AS ca_state,
        ib.ib_lower_bound AS ib_lower_bound,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE cs.cs_net_paid > (SELECT avg_net_paid FROM avg_net_paid)
      AND EXISTS (
          SELECT 1
          FROM web_sales ws
          WHERE ws.ws_bill_customer_sk = cs.cs_bill_customer_sk
      )
    GROUP BY CUBE (i.i_category, i.i_brand, ca.ca_state, ib.ib_lower_bound)
),
-- Extract distinct dimension keys from the sales aggregation
sales_keys AS (
    SELECT DISTINCT i_category, i_brand, ca_state, ib_lower_bound
    FROM sales_agg
),
-- Extract distinct dimension keys from catalog returns
returns_keys AS (
    SELECT DISTINCT
        i.i_category AS i_category,
        i.i_brand AS i_brand,
        ca.ca_state AS ca_state,
        ib.ib_lower_bound AS ib_lower_bound
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
),
-- Keys present in sales but not in returns
keys_without_returns AS (
    SELECT *
    FROM sales_keys
    EXCEPT
    SELECT *
    FROM returns_keys
)
SELECT
    sa.i_category,
    sa.i_brand,
    sa.ca_state,
    sa.ib_lower_bound,
    sa.total_net_paid,
    sa.sales_cnt
FROM sales_agg sa
JOIN keys_without_returns kwr
  ON (sa.i_category IS NOT DISTINCT FROM kwr.i_category
      AND sa.i_brand IS NOT DISTINCT FROM kwr.i_brand
      AND sa.ca_state IS NOT DISTINCT FROM kwr.ca_state
      AND sa.ib_lower_bound IS NOT DISTINCT FROM kwr.ib_lower_bound)
ORDER BY sa.total_net_paid DESC
LIMIT 100
