WITH catalog_agg AS (
   SELECT
     i.i_item_id AS item_id,
     i.i_product_name AS product_name,
     d.d_year AS year,
     d.d_month_seq AS month_seq,
     SUM(cs.cs_net_paid) AS sales_amount,
     SUM(cr.cr_net_loss) AS returns_amount,
     COUNT(DISTINCT cs.cs_order_number) AS orders_cnt,
     hd.hd_income_band_sk AS income_band_sk
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN item i ON cs.cs_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
   LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
   LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2000
     AND i.i_brand = 'BrandX'
     AND hd.hd_buy_potential = '0-500'
     AND sm.sm_type = 'AIR'
   GROUP BY i.i_item_id, i.i_product_name, d.d_year, d.d_month_seq, hd.hd_income_band_sk
),
web_agg AS (
   SELECT
     i.i_item_id AS item_id,
     i.i_product_name AS product_name,
     d.d_year AS year,
     d.d_month_seq AS month_seq,
     SUM(ws.ws_net_paid) AS sales_amount,
     SUM(wr.wr_net_loss) AS returns_amount,
     COUNT(DISTINCT ws.ws_order_number) AS orders_cnt,
     hd.hd_income_band_sk AS income_band_sk
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN item i ON ws.ws_item_sk = i.i_item_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
   LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
   LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
   LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
   LEFT JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk AND ss.ss_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2000
     AND i.i_brand = 'BrandX'
     AND hd.hd_buy_potential = '0-500'
     AND we.web_country = 'United States'
   GROUP BY i.i_item_id, i.i_product_name, d.d_year, d.d_month_seq, hd.hd_income_band_sk
)
SELECT
   item_id,
   product_name,
   year,
   month_seq,
   sales_amount,
   returns_amount,
   orders_cnt,
   (sales_amount - returns_amount) AS net_amount,
   RANK() OVER (PARTITION BY year ORDER BY (sales_amount - returns_amount) DESC) AS sales_rank
FROM (
   SELECT * FROM catalog_agg
   UNION ALL
   SELECT * FROM web_agg
) AS combined
WHERE EXISTS (
   SELECT 1 FROM income_band ib
   WHERE ib.ib_income_band_sk = combined.income_band_sk
     AND ib.ib_upper_bound > 50000
)
ORDER BY net_amount DESC
LIMIT 100
