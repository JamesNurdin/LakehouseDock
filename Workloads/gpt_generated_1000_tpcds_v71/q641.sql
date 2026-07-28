WITH
  ss_agg AS (
    SELECT
      ss_store_sk,
      ss_sold_date_sk,
      SUM(ss_net_paid)            AS store_net_paid,
      SUM(ss_ext_sales_price)     AS store_ext_sales,
      COUNT(*)                    AS store_txn_cnt
    FROM store_sales
    WHERE ss_sold_date_sk IN (
          SELECT d_date_sk FROM date_dim WHERE d_year = 2001
        )
    GROUP BY ss_store_sk, ss_sold_date_sk
  ),
  cs_agg AS (
    SELECT
      cs_call_center_sk,
      cs_catalog_page_sk,
      cs_ship_mode_sk,
      cs_sold_date_sk,
      SUM(cs_net_paid)            AS catalog_net_paid,
      SUM(cs_ext_sales_price)     AS catalog_ext_sales,
      COUNT(*)                    AS catalog_txn_cnt
    FROM catalog_sales
    WHERE cs_sold_date_sk IN (
          SELECT d_date_sk FROM date_dim WHERE d_year = 2001
        )
      AND cs_wholesale_cost > 20
    GROUP BY cs_call_center_sk, cs_catalog_page_sk, cs_ship_mode_sk, cs_sold_date_sk
  )
SELECT
  d.d_year,
  s.s_store_name,
  s.s_state,
  cc.cc_market_manager,
  cp.cp_type,
  sm.sm_type,
  r.r_reason_desc,
  SUM(ss_agg.store_net_paid)          AS total_store_net_paid,
  SUM(cs_agg.catalog_net_paid)        AS total_catalog_net_paid,
  SUM(cr.cr_return_amount)            AS total_catalog_return_amt,
  SUM(wr.wr_return_amt)               AS total_web_return_amt,
  SUM(sr.sr_return_amt)               AS total_store_return_amt,
  COUNT(DISTINCT ss_agg.ss_store_sk)  AS distinct_stores,
  AVG(cs_agg.catalog_ext_sales)       AS avg_catalog_ext_sales
FROM ss_agg
JOIN store s               ON ss_agg.ss_store_sk = s.s_store_sk
JOIN date_dim d            ON ss_agg.ss_sold_date_sk = d.d_date_sk
JOIN cs_agg               ON cs_agg.cs_sold_date_sk = d.d_date_sk
JOIN catalog_page cp      ON cs_agg.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN call_center cc       ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm         ON cs_agg.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store_returns sr     ON sr.sr_store_sk = s.s_store_sk
                           AND sr.sr_returned_date_sk = d.d_date_sk
JOIN reason r             ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_returns wr      ON wr.wr_returned_date_sk = d.d_date_sk
JOIN web_page wp          ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN catalog_returns cr  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t_sr        ON sr.sr_return_time_sk = t_sr.t_time_sk
JOIN time_dim t_cr        ON cr.cr_returned_time_sk = t_cr.t_time_sk
JOIN inventory i          ON i.inv_date_sk = d.d_date_sk
JOIN customer c          ON sr.sr_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
WHERE d.d_year = 2001
  AND s.s_state = 'CA'
  AND cp.cp_type = 'monthly'
  AND r.r_reason_desc = 'Damaged'
  AND sm.sm_type = 'AIR'
  AND cc.cc_market_manager = 'John Miller'
GROUP BY
  d.d_year,
  s.s_store_name,
  s.s_state,
  cc.cc_market_manager,
  cp.cp_type,
  sm.sm_type,
  r.r_reason_desc
ORDER BY total_store_net_paid DESC
LIMIT 100
