WITH
  /* Alias date_dim for different roles */
  date_sales AS (SELECT * FROM date_dim),
  date_return AS (SELECT * FROM date_dim)
SELECT
  s.s_store_name,
  i.i_category,
  p.p_promo_name,
  ds.d_year,
  SUM(ss.ss_ext_sales_price) AS total_store_sales,
  SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
  SUM(cr.cr_return_amount) AS total_catalog_returns,
  SUM(wr.wr_return_amt) AS total_web_returns,
  (SUM(ss.ss_net_profit) - SUM(cr.cr_net_loss) - SUM(wr.wr_net_loss)) AS net_profit_adjusted
FROM
  store_sales ss
  JOIN date_sales ds
    ON ss.ss_sold_date_sk = ds.d_date_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
  JOIN income_band ib_ss
    ON hd_ss.hd_income_band_sk = ib_ss.ib_income_band_sk
  JOIN catalog_sales cs
    ON ss.ss_item_sk = cs.cs_item_sk
   AND ss.ss_sold_date_sk = cs.cs_sold_date_sk
  JOIN catalog_returns cr
    ON cs.cs_order_number = cr.cr_order_number
   AND i.i_item_sk = cr.cr_item_sk
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN date_return dr
    ON cr.cr_returned_date_sk = dr.d_date_sk
  JOIN web_returns wr
    ON i.i_item_sk = wr.wr_item_sk
   AND ds.d_date_sk = wr.wr_returned_date_sk
  JOIN web_site ws
    ON ws.web_open_date_sk = ds.d_date_sk
WHERE
  EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = ss.ss_item_sk
      AND wr2.wr_returned_date_sk = ds.d_date_sk
      AND wr2.wr_return_quantity > 0
  )
  AND p.p_channel_tv = 'N'
  AND s.s_country = 'United States'
GROUP BY
  s.s_store_name,
  i.i_category,
  p.p_promo_name,
  ds.d_year
ORDER BY
  net_profit_adjusted DESC
LIMIT 100
