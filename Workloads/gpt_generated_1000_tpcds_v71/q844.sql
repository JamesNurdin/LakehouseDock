WITH sales AS (
   SELECT
     s.s_store_sk,
     s.s_store_name,
     i.i_item_sk,
     i.i_item_id,
     d_sales.d_year,
     SUM(ss.ss_net_profit)               AS total_store_profit,
     SUM(ss.ss_ext_sales_price)          AS total_sales_amount
   FROM store_sales ss
   JOIN date_dim d_sales
     ON ss.ss_sold_date_sk = d_sales.d_date_sk
   JOIN store s
     ON ss.ss_store_sk = s.s_store_sk
   JOIN item i
     ON ss.ss_item_sk = i.i_item_sk
   JOIN customer c
     ON ss.ss_customer_sk = c.c_customer_sk
   JOIN customer_demographics cd
     ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd
     ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib
     ON hd.hd_income_band_sk = ib.ib_income_band_sk
   LEFT JOIN store_returns sr
     ON ss.ss_ticket_number = sr.sr_ticket_number
   LEFT JOIN inventory inv
     ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_date_sk = d_sales.d_date_sk
   LEFT JOIN warehouse w_inv
     ON inv.inv_warehouse_sk = w_inv.w_warehouse_sk
   GROUP BY s.s_store_sk, s.s_store_name, i.i_item_sk, i.i_item_id, d_sales.d_year
   HAVING SUM(ss.ss_net_profit) > 5000
),

catalog_ret AS (
   SELECT
     i.i_item_sk,
     d_cr.d_year,
     SUM(cr.cr_net_loss)                AS catalog_return_loss,
     cc.cc_name                         AS call_center_name,
     cp.cp_department                   AS catalog_department,
     sm.sm_type                         AS ship_mode_type,
     w_cr.w_warehouse_name              AS warehouse_name
   FROM catalog_returns cr
   JOIN date_dim d_cr
     ON cr.cr_returned_date_sk = d_cr.d_date_sk
   JOIN item i
     ON cr.cr_item_sk = i.i_item_sk
   JOIN call_center cc
     ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
     ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm
     ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w_cr
     ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
   GROUP BY i.i_item_sk, d_cr.d_year, cc.cc_name, cp.cp_department, sm.sm_type, w_cr.w_warehouse_name
),

web_ret AS (
   SELECT
     i.i_item_sk,
     d_wr.d_year,
     SUM(wr.wr_net_loss)                AS web_return_loss
   FROM web_returns wr
   JOIN date_dim d_wr
     ON wr.wr_returned_date_sk = d_wr.d_date_sk
   JOIN item i
     ON wr.wr_item_sk = i.i_item_sk
   GROUP BY i.i_item_sk, d_wr.d_year
)
SELECT
  s.s_store_name,
  s.i_item_id,
  s.d_year,
  s.total_store_profit,
  cr.catalog_return_loss,
  wr.web_return_loss,
  CASE WHEN s.total_store_profit - (cr.catalog_return_loss + wr.web_return_loss) > 0
       THEN 'PROFIT'
       ELSE 'LOSS' END                                 AS overall_status,
  (SELECT AVG(ss2.ss_net_profit)
     FROM store_sales ss2
    WHERE ss2.ss_item_sk = s.i_item_sk)               AS avg_item_profit,
  ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY s.total_store_profit DESC) AS profit_rank
FROM sales s
LEFT JOIN catalog_ret cr
  ON s.i_item_sk = cr.i_item_sk AND s.d_year = cr.d_year
LEFT JOIN web_ret wr
  ON s.i_item_sk = wr.i_item_sk AND s.d_year = wr.d_year
WHERE s.total_sales_amount > 10000
ORDER BY s.total_store_profit DESC
LIMIT 100
