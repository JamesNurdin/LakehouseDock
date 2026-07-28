/*
  Goal: Compute total net paid and total net profit for the year 2001, broken down by month, item category, and call‑center name, for preferred customers belonging to a specific income band, buying items in a given price range and shipped via a selected ship‑mode. The query also ensures that the web site is located in CA and that at least one web sale existed for the same month (semi‑join via EXISTS).
*/
WITH
  -- Catalog sales base
  cs_base AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cs.cs_bill_customer_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_item_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_ship_mode_sk
    FROM catalog_sales cs
  ),
  -- Store sales base
  ss_base AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_net_paid,
      ss.ss_net_profit,
      ss.ss_customer_sk,
      ss.ss_hdemo_sk,
      ss.ss_item_sk
    FROM store_sales ss
  )
SELECT
  d_cs.d_year,
  d_cs.d_month_seq,
  i_cs.i_category,
  cc.cc_name,
  SUM(cs_base.cs_net_paid)                AS catalog_net_paid,
  SUM(cs_base.cs_net_profit)              AS catalog_net_profit,
  SUM(ss_base.ss_net_paid)                AS store_net_paid,
  SUM(ss_base.ss_net_profit)              AS store_net_profit,
  COUNT(DISTINCT c_pref.c_customer_sk)    AS preferred_customer_cnt
FROM cs_base
INNER JOIN date_dim d_cs
        ON cs_base.cs_sold_date_sk = d_cs.d_date_sk
INNER JOIN time_dim t_cs
        ON cs_base.cs_sold_time_sk = t_cs.t_time_sk
INNER JOIN item i_cs
        ON cs_base.cs_item_sk = i_cs.i_item_sk
INNER JOIN customer c_bill
        ON cs_base.cs_bill_customer_sk = c_bill.c_customer_sk
INNER JOIN household_demographics hd_bill
        ON cs_base.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
INNER JOIN income_band ib
        ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
INNER JOIN call_center cc
        ON cs_base.cs_call_center_sk = cc.cc_call_center_sk
INNER JOIN catalog_page cp
        ON cs_base.cs_catalog_page_sk = cp.cp_catalog_page_sk
INNER JOIN ship_mode sm
        ON cs_base.cs_ship_mode_sk = sm.sm_ship_mode_sk
-- Preferred‑customer filter (using the same customer table but with a different alias for clarity)
INNER JOIN customer c_pref
        ON c_bill.c_customer_sk = c_pref.c_customer_sk
        AND c_pref.c_preferred_cust_flag = 'Y'
-- Store‑sales branch
INNER JOIN ss_base
        ON ss_base.ss_sold_date_sk = d_cs.d_date_sk
        AND ss_base.ss_sold_time_sk = t_cs.t_time_sk
INNER JOIN item i_ss
        ON ss_base.ss_item_sk = i_ss.i_item_sk
INNER JOIN household_demographics hd_ss
        ON ss_base.ss_hdemo_sk = hd_ss.hd_demo_sk
INNER JOIN customer c_ss
        ON ss_base.ss_customer_sk = c_ss.c_customer_sk
-- Web‑site branch (joined directly, web_sales used only in EXISTS)
INNER JOIN web_site ws
        ON ws.web_open_date_sk = d_cs.d_date_sk
        AND ws.web_state = 'CA'
WHERE
  -- Date filter for the year 2001
  d_cs.d_year = 2001
  AND d_cs.d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
  -- Item price range filter
  AND i_cs.i_current_price BETWEEN 50 AND 200
  -- Specific income band
  AND ib.ib_income_band_sk = 5
  -- Ship‑mode filter
  AND sm.sm_type = 'AIR'
  -- Household vehicle count must be positive (additional selective predicate)
  AND hd_bill.hd_vehicle_count > 0
  -- Catalog page department filter (realistic literal)
  AND cp.cp_department = 'Electronics'
  -- Ensure at least one web sale exists for the same month and site (semi‑join)
  AND EXISTS (
        SELECT 1
        FROM web_sales wsale
        WHERE wsale.ws_web_site_sk = ws.web_site_sk
          AND wsale.ws_sold_date_sk = d_cs.d_date_sk
          AND wsale.ws_quantity > 0
      )
GROUP BY
  d_cs.d_year,
  d_cs.d_month_seq,
  i_cs.i_category,
  cc.cc_name
ORDER BY
  d_cs.d_year,
  d_cs.d_month_seq,
  i_cs.i_category,
  cc.cc_name
LIMIT 100
