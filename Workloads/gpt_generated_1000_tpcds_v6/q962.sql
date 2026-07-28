WITH catalog_agg AS (
   SELECT
       d.d_year AS year,
       r.r_reason_desc AS reason,
       SUM(cs.cs_net_paid) AS sales_amount,
       SUM(cr.cr_net_loss) AS return_loss,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_net_paid) DESC) AS rank
   FROM catalog_sales cs
   JOIN catalog_returns cr
     ON cs.cs_item_sk = cr.cr_item_sk
    AND cs.cs_order_number = cr.cr_order_number
   JOIN date_dim d
     ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN date_dim d_ret
     ON cr.cr_returned_date_sk = d_ret.d_date_sk
   JOIN catalog_page cp
     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w
     ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN reason r
     ON cr.cr_reason_sk = r.r_reason_sk
   JOIN customer_demographics cd
     ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   GROUP BY d.d_year, r.r_reason_desc
),
store_agg AS (
   SELECT
       d.d_year AS year,
       r.r_reason_desc AS reason,
       SUM(sr.sr_return_amt) AS store_return_amount,
       SUM(sr.sr_net_loss) AS store_net_loss,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(sr.sr_return_amt) DESC) AS rank
   FROM store_returns sr
   JOIN date_dim d
     ON sr.sr_returned_date_sk = d.d_date_sk
   JOIN reason r
     ON sr.sr_reason_sk = r.r_reason_sk
   GROUP BY d.d_year, r.r_reason_desc
),
web_agg AS (
   SELECT
       d.d_year AS year,
       r.r_reason_desc AS reason,
       SUM(wr.wr_return_amt) AS web_return_amount,
       SUM(wr.wr_net_loss) AS web_net_loss,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(wr.wr_return_amt) DESC) AS rank
   FROM web_returns wr
   JOIN date_dim d
     ON wr.wr_returned_date_sk = d.d_date_sk
   JOIN reason r
     ON wr.wr_reason_sk = r.r_reason_sk
   GROUP BY d.d_year, r.r_reason_desc
),
inventory_agg AS (
   SELECT
       d.d_year AS year,
       w.w_warehouse_name AS reason,
       NULL AS sales_amount,
       NULL AS return_loss,
       SUM(inv.inv_quantity_on_hand) AS store_return_amount,
       NULL AS web_return_amount,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(inv.inv_quantity_on_hand) DESC) AS rank
   FROM inventory inv
   JOIN date_dim d
     ON inv.inv_date_sk = d.d_date_sk
   JOIN warehouse w
     ON inv.inv_warehouse_sk = w.w_warehouse_sk
   GROUP BY d.d_year, w.w_warehouse_name
),
web_site_agg AS (
   SELECT
       d.d_year AS year,
       ws.web_name AS reason,
       NULL AS sales_amount,
       NULL AS return_loss,
       NULL AS store_return_amount,
       NULL AS web_return_amount,
       ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY COUNT(*) DESC) AS rank
   FROM web_site ws
   JOIN date_dim d
     ON ws.web_open_date_sk = d.d_date_sk
   GROUP BY d.d_year, ws.web_name
),
combined AS (
   SELECT year, reason, sales_amount, return_loss, NULL AS store_return_amount, NULL AS web_return_amount, rank FROM catalog_agg
   UNION ALL
   SELECT year, reason, NULL, NULL, store_return_amount, NULL, rank FROM store_agg
   UNION ALL
   SELECT year, reason, NULL, NULL, NULL, web_return_amount, rank FROM web_agg
   UNION ALL
   SELECT year, reason, NULL, NULL, store_return_amount, NULL, rank FROM inventory_agg
   UNION ALL
   SELECT year, reason, NULL, NULL, NULL, NULL, rank FROM web_site_agg
)
SELECT
   year,
   reason,
   SUM(sales_amount) AS total_sales,
   SUM(return_loss) AS total_return_loss,
   SUM(COALESCE(store_return_amount, 0) + COALESCE(web_return_amount, 0)) AS total_returns,
   CASE
       WHEN SUM(COALESCE(store_return_amount, 0)) > SUM(COALESCE(web_return_amount, 0)) THEN 'STORE'
       ELSE 'WEB'
   END AS dominant_return_source,
   MAX(rank) AS max_rank
FROM combined
GROUP BY GROUPING SETS ((year, reason), (year), ())
ORDER BY year DESC, total_sales DESC
LIMIT 100
