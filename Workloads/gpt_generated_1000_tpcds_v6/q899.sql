WITH
  -- Sales aggregation with deep joins and a window function
  sales_data AS (
    SELECT
      s.s_store_name                     AS dim_name,
      d_sales.d_year                     AS year,
      SUM(ss.ss_net_paid)               AS amount,
      CASE WHEN SUM(ss.ss_net_paid) > 100000 THEN 'High' ELSE 'Low' END AS category,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY SUM(ss.ss_net_paid) DESC) AS rank_within_store,
      (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) AS avg_net_paid_all
    FROM store_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN customer c_sales ON ss.ss_customer_sk = c_sales.c_customer_sk
    JOIN household_demographics hd_sales ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
    JOIN income_band ib ON hd_sales.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    -- join web_site via the store closed date (date_dim aliased differently)
    JOIN date_dim d_site ON s.s_closed_date_sk = d_site.d_date_sk
    JOIN web_site ws ON d_site.d_date_sk = ws.web_close_date_sk
    WHERE d_sales.d_year = 2001
      AND EXISTS (
        SELECT 1
        FROM web_page wp
        WHERE wp.wp_customer_sk = c_sales.c_customer_sk
          AND wp.wp_type = 'article'
      )
    GROUP BY ROLLUP (s.s_store_name, d_sales.d_year, p.p_promo_name)
  ),

  -- Catalog returns aggregation
  catalog_returns_data AS (
    SELECT
      cc.cc_name                         AS dim_name,
      d_ret.d_year                       AS year,
      SUM(cr.cr_return_amount)           AS amount,
      CASE WHEN SUM(cr.cr_return_amount) > 5000 THEN 'Large' ELSE 'Small' END AS category,
      NULL                               AS avg_net_paid_all
    FROM catalog_returns cr
    JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN time_dim t_ret ON cr.cr_returned_time_sk = t_ret.t_time_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
    JOIN household_demographics hd_refund ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
    JOIN income_band ib2 ON hd_refund.hd_income_band_sk = ib2.ib_income_band_sk
    WHERE d_ret.d_year = 2001
    GROUP BY CUBE (cc.cc_name, d_ret.d_year)
  ),

  -- Web returns aggregation
  web_returns_data AS (
    SELECT
      wp.wp_url                         AS dim_name,
      d_wr.d_year                       AS year,
      SUM(wr.wr_return_amt)             AS amount,
      CASE WHEN SUM(wr.wr_return_amt) > 3000 THEN 'High' ELSE 'Low' END AS category,
      NULL                               AS avg_net_paid_all
    FROM web_returns wr
    JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer c_refund_wr ON wr.wr_refunded_customer_sk = c_refund_wr.c_customer_sk
    JOIN household_demographics hd_refund_wr ON wr.wr_refunded_hdemo_sk = hd_refund_wr.hd_demo_sk
    JOIN income_band ib_wr ON hd_refund_wr.hd_income_band_sk = ib_wr.ib_income_band_sk
    WHERE d_wr.d_year = 2001
    GROUP BY GROUPING SETS ((wp.wp_url, d_wr.d_year), ())
  )

-- Combine the three result sets with a set operation
SELECT
  source_type,
  dim_name,
  year,
  amount,
  category,
  avg_net_paid_all,
  ROW_NUMBER() OVER (PARTITION BY source_type ORDER BY amount DESC) AS overall_rank
FROM (
  SELECT 'Sales'          AS source_type, dim_name, year, amount, category, avg_net_paid_all FROM sales_data
  UNION ALL
  SELECT 'CatalogReturn'  AS source_type, dim_name, year, amount, category, avg_net_paid_all FROM catalog_returns_data
  UNION ALL
  SELECT 'WebReturn'      AS source_type, dim_name, year, amount, category, avg_net_paid_all FROM web_returns_data
) AS combined
ORDER BY year DESC, amount DESC
LIMIT 100
