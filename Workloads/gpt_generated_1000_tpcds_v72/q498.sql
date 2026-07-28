/*
  Goal:  Analyze combined retail performance across store sales, web sales and catalog returns for California stores in 2002, 
         focusing on a specific brand and time window, and breaking down results by state, year and item category.
         The query joins all 18 selected TPC‑DS tables using only the permitted join keys, applies six realistic filter predicates, 
         uses a CASE expression to isolate book sales, and aggregates with a ROLLUP grouping set.  Results are ordered by total 
         store sales and limited to the top 100 rows.
*/
WITH
  ss AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_sold_time_sk,
      ss.ss_item_sk,
      ss.ss_ext_sales_price,
      ss.ss_ticket_number,
      d.d_year            AS d_year,
      t.t_hour            AS t_hour,
      i.i_category        AS i_category,
      i.i_brand           AS i_brand,
      s.s_state,
      s.s_market_id,
      p.p_discount_active,
      ca.ca_city,
      ib.ib_upper_bound
    FROM store_sales ss
    JOIN date_dim d      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t      ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i          ON ss.ss_item_sk      = i.i_item_sk
    JOIN customer c      ON ss.ss_customer_sk  = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib  ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s         ON ss.ss_store_sk     = s.s_store_sk
    JOIN promotion p     ON ss.ss_promo_sk     = p.p_promo_sk
  ),

  ws AS (
    SELECT
      ws.ws_sold_date_sk,
      ws.ws_sold_time_sk,
      ws.ws_item_sk,
      ws.ws_ext_sales_price,
      ws.ws_order_number,
      d.d_year            AS ws_year,
      t.t_hour            AS ws_hour,
      i.i_category        AS ws_category,
      i.i_brand           AS ws_brand,
      ca.ca_city          AS ws_city,
      p.p_discount_active AS ws_promo_active,
      wp.wp_type,
      web.web_name
    FROM web_sales ws
    JOIN date_dim d      ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t      ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i          ON ws.ws_item_sk      = i.i_item_sk
    JOIN customer c      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib  ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p     ON ws.ws_promo_sk     = p.p_promo_sk
    JOIN web_page wp     ON ws.ws_web_page_sk  = wp.wp_web_page_sk
    JOIN web_site web    ON ws.ws_web_site_sk  = web.web_site_sk
  ),

  cr AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_returned_time_sk,
      cr.cr_item_sk,
      cr.cr_return_amount,
      d.d_year            AS cr_year,
      t.t_hour            AS cr_hour,
      i.i_category        AS cr_category,
      i.i_brand           AS cr_brand,
      ca_ref.ca_city      AS refunded_city,
      ca_ret.ca_city      AS returning_city,
      cc.cc_class,
      cp.cp_type,
      r.r_reason_desc
    FROM catalog_returns cr
    JOIN date_dim d      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN time_dim t      ON cr.cr_returned_time_sk = t.t_time_sk
    JOIN item i          ON cr.cr_item_sk      = i.i_item_sk
    JOIN customer c_ref  ON cr.cr_refunded_customer_sk = c_ref.c_customer_sk
    JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
    JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
    JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer c_ret  ON cr.cr_returning_customer_sk = c_ret.c_customer_sk
    JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
    JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
    JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN call_center cc  ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN reason r        ON cr.cr_reason_sk      = r.r_reason_sk
  )
SELECT
  s_state,
  d_year,
  i_category,
  SUM(ss_ext_sales_price)                         AS total_store_sales,
  SUM(ws_ext_sales_price)                         AS total_web_sales,
  SUM(cr_return_amount)                           AS total_returns,
  COUNT(DISTINCT ss_ticket_number)                AS store_transactions,
  COUNT(DISTINCT ws_order_number)                 AS web_orders,
  SUM(CASE WHEN i_category = 'Books' THEN ss_ext_sales_price ELSE 0 END) AS book_store_sales,
  AVG(ib_upper_bound)                             AS avg_income_upper_bound,
  MAX(CASE WHEN cc_class = 'large' THEN ss_ext_sales_price ELSE NULL END) AS max_large_cc_store_sales
FROM ss
JOIN ws ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
        AND ss.ss_sold_time_sk = ws.ws_sold_time_sk
        AND ss.ss_item_sk     = ws.ws_item_sk
JOIN cr ON ss.ss_sold_date_sk = cr.cr_returned_date_sk
        AND ss.ss_item_sk     = cr.cr_item_sk
WHERE
  s_state            = 'CA'
  AND s_market_id    IN (1, 3)
  AND p_discount_active = 'Y'
  AND i_brand        = 'Brand#12'
  AND d_year         = 2002
  AND t_hour BETWEEN 9 AND 17
  AND ca_city         = 'Ash 8th'
GROUP BY ROLLUP (s_state, d_year, i_category)
ORDER BY total_store_sales DESC
LIMIT 100
