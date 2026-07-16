WITH sales AS (
   SELECT
       cs.cs_item_sk AS item_sk,
       cs.cs_ship_mode_sk AS ship_mode_sk,
       cs.cs_bill_cdemo_sk AS bill_cdemo_sk,
       cs.cs_bill_hdemo_sk AS bill_hdemo_sk,
       d.d_year AS year,
       d.d_quarter_name AS quarter_name,
       SUM(cs.cs_net_profit) AS sales_profit,
       SUM(cs.cs_quantity) AS sales_qty,
       AVG(cs.cs_ext_discount_amt) AS avg_discount,
       SUM(cs.cs_ext_ship_cost) AS total_ship_cost
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   WHERE d.d_year = 2020
     AND d.d_quarter_name = 'Q4'
     AND cd.cd_gender = 'F'
     AND cd.cd_marital_status = 'M'
   GROUP BY cs.cs_item_sk, cs.cs_ship_mode_sk, cs.cs_bill_cdemo_sk, cs.cs_bill_hdemo_sk, d.d_year, d.d_quarter_name
),
returns AS (
   SELECT
       cr.cr_item_sk AS item_sk,
       cr.cr_ship_mode_sk AS ship_mode_sk,
       cr.cr_refunded_cdemo_sk AS bill_cdemo_sk,
       cr.cr_refunded_hdemo_sk AS bill_hdemo_sk,
       d_ret.d_year AS year,
       d_ret.d_quarter_name AS quarter_name,
       SUM(cr.cr_return_amount) AS return_amount,
       SUM(cr.cr_return_quantity) AS return_qty,
       COUNT(*) AS return_cnt
   FROM catalog_returns cr
   JOIN date_dim d_ret ON cr.cr_returned_date_sk = d_ret.d_date_sk
   JOIN customer_demographics cd_ret ON cr.cr_refunded_cdemo_sk = cd_ret.cd_demo_sk
   JOIN household_demographics hd_ret ON cr.cr_refunded_hdemo_sk = hd_ret.hd_demo_sk
   WHERE d_ret.d_year = 2020
     AND d_ret.d_quarter_name = 'Q4'
     AND cd_ret.cd_gender = 'F'
     AND cd_ret.cd_marital_status = 'M'
   GROUP BY cr.cr_item_sk, cr.cr_ship_mode_sk, cr.cr_refunded_cdemo_sk, cr.cr_refunded_hdemo_sk, d_ret.d_year, d_ret.d_quarter_name
)
SELECT
   i.i_category,
   sm.sm_type,
   SUM(COALESCE(s.sales_profit, 0) - COALESCE(r.return_amount, 0)) AS net_profit_adj,
   SUM(COALESCE(s.sales_qty, 0)) AS total_sales_qty,
   SUM(COALESCE(r.return_qty, 0)) AS total_return_qty,
   CASE WHEN SUM(COALESCE(s.sales_qty, 0)) = 0 THEN 0
        ELSE CAST(SUM(COALESCE(r.return_qty, 0)) AS double) / CAST(SUM(COALESCE(s.sales_qty, 0)) AS double) END AS return_rate,
   AVG(s.avg_discount) AS avg_discount,
   SUM(s.total_ship_cost) AS total_ship_cost
FROM sales s
FULL OUTER JOIN returns r
   ON s.item_sk = r.item_sk
   AND s.ship_mode_sk = r.ship_mode_sk
   AND s.bill_cdemo_sk = r.bill_cdemo_sk
   AND s.bill_hdemo_sk = r.bill_hdemo_sk
   AND s.year = r.year
   AND s.quarter_name = r.quarter_name
JOIN item i
   ON COALESCE(s.item_sk, r.item_sk) = i.i_item_sk
JOIN ship_mode sm
   ON COALESCE(s.ship_mode_sk, r.ship_mode_sk) = sm.sm_ship_mode_sk
GROUP BY i.i_category, sm.sm_type
HAVING SUM(COALESCE(s.sales_profit, 0) - COALESCE(r.return_amount, 0)) > 0
ORDER BY net_profit_adj DESC
LIMIT 5
