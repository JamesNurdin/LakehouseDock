WITH
  store_sales_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      SUM(ss.ss_net_profit) AS profit,
      0 AS loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_current_price > 50
      AND s.s_state = 'TX'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = '5000-10000'
      AND ss.ss_quantity > 1
    GROUP BY d.d_year, i.i_category
  ),

  store_returns_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      0 AS profit,
      SUM(sr.sr_net_loss) AS loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
      AND i.i_current_price > 50
      AND s.s_state = 'TX'
      AND cd.cd_gender = 'M'
      AND hd.hd_buy_potential = '5000-10000'
      AND sr.sr_return_quantity > 0
    GROUP BY d.d_year, i.i_category
  ),

  catalog_sales_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      SUM(cs.cs_net_profit) AS profit,
      0 AS loss
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20
      AND cc.cc_tax_percentage > 5
      AND cp.cp_type = 'Online'
      AND cd.cd_marital_status = 'M'
      AND hd.hd_buy_potential = '1000-5000'
    GROUP BY d.d_year, i.i_category
  ),

  catalog_returns_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      0 AS profit,
      SUM(cr.cr_net_loss) AS loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20
      AND cc.cc_tax_percentage > 5
      AND cp.cp_type = 'Online'
      AND cd.cd_marital_status = 'M'
      AND hd.hd_buy_potential = '1000-5000'
    GROUP BY d.d_year, i.i_category
  ),

  web_returns_agg AS (
    SELECT
      d.d_year AS year,
      i.i_category AS category,
      0 AS profit,
      SUM(wr.wr_net_loss) AS loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 20
      AND wp.wp_type = 'Content'
      AND cd.cd_gender = 'F'
      AND hd.hd_buy_potential = '5000-10000'
      AND wp.wp_char_count > 5000
    GROUP BY d.d_year, i.i_category
  ),

  call_center_agg AS (
    SELECT
      d.d_year AS year,
      'CALL_CENTER' AS category,
      SUM(cc.cc_tax_percentage) AS profit,
      0 AS loss
    FROM call_center cc
    JOIN date_dim d ON cc.cc_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cc.cc_employees > 50
      AND cc.cc_sq_ft > 20000
      AND cc.cc_gmt_offset >= -5
      AND cc.cc_market_manager = 'Albert Leung'
      AND cc.cc_class = 'CLASSA'
    GROUP BY d.d_year
  ),

  web_site_agg AS (
    SELECT
      d.d_year AS year,
      'WEB_SITE' AS category,
      SUM(ws.web_tax_percentage) AS profit,
      0 AS loss
    FROM web_site ws
    JOIN date_dim d ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ws.web_market_manager = 'Edward George'
      AND ws.web_country = 'United States'
      AND ws.web_tax_percentage > 5
      AND ws.web_suite_number LIKE 'Suite %'
      AND ws.web_city = 'San Francisco'
    GROUP BY d.d_year
  ),

  income_band_agg AS (
    SELECT
      0 AS year,
      'INCOME_BAND' AS category,
      SUM(ib.ib_upper_bound - ib.ib_lower_bound) AS profit,
      0 AS loss
    FROM income_band ib
    JOIN household_demographics hd ON ib.ib_income_band_sk = hd.hd_income_band_sk
    GROUP BY ib.ib_income_band_sk
  ),

  combined AS (
    SELECT
      year,
      category,
      SUM(profit) AS profit,
      SUM(loss) AS loss
    FROM (
      SELECT year, category, profit, loss FROM store_sales_agg
      UNION ALL
      SELECT year, category, profit, loss FROM store_returns_agg
      UNION ALL
      SELECT year, category, profit, loss FROM catalog_sales_agg
      UNION ALL
      SELECT year, category, profit, loss FROM catalog_returns_agg
      UNION ALL
      SELECT year, category, profit, loss FROM web_returns_agg
      UNION ALL
      SELECT year, category, profit, loss FROM call_center_agg
      UNION ALL
      SELECT year, category, profit, loss FROM web_site_agg
      UNION ALL
      SELECT year, category, profit, loss FROM income_band_agg
    ) t
    GROUP BY year, category
    HAVING SUM(profit) > 5000
  )

SELECT DISTINCT
  c.year,
  c.category,
  c.profit,
  c.loss
FROM combined c
WHERE c.year NOT IN (
  SELECT d2.d_year
  FROM date_dim d2
  JOIN store_sales ss2 ON ss2.ss_sold_date_sk = d2.d_date_sk
  WHERE ss2.ss_quantity = 0
)
ORDER BY c.profit DESC
LIMIT 100
