WITH ss_agg AS (
    SELECT ss_item_sk,
           SUM(ss_net_paid) AS ss_total_net_paid,
           SUM(ss_ext_sales_price) AS ss_total_ext_sales_price,
           COUNT(*) AS ss_txn_count
    FROM store_sales
    GROUP BY ss_item_sk
),
wr_agg AS (
    SELECT wr_item_sk,
           SUM(wr_return_amt) AS wr_total_return_amt,
           SUM(wr_net_loss) AS wr_total_net_loss,
           COUNT(*) AS wr_txn_count
    FROM web_returns
    GROUP BY wr_item_sk
)
SELECT d.d_year,
       cc.cc_name,
       r.r_reason_desc,
       i.i_brand,
       cp.cp_department,
       SUM(cs.cs_net_paid) AS total_sales_net_paid,
       SUM(cs.cs_net_paid_inc_tax) AS total_sales_net_paid_inc_tax,
       SUM(cs.cs_ext_sales_price) AS total_sales_ext_price,
       COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
       SUM(cr.cr_return_amount) AS total_return_amount,
       SUM(ss_agg.ss_total_net_paid) AS total_store_sales_net_paid,
       SUM(wr_agg.wr_total_return_amt) AS total_web_return_amount,
       AVG(cs.cs_quantity) AS avg_quantity,
       MIN(cs.cs_sales_price) AS min_sales_price,
       MAX(cs.cs_sales_price) AS max_sales_price
FROM catalog_sales cs
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN catalog_returns cr ON cr.cr_item_sk = cs.cs_item_sk AND cr.cr_order_number = cs.cs_order_number
JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
JOIN ss_agg ON ss_agg.ss_item_sk = i.i_item_sk
JOIN wr_agg ON wr_agg.wr_item_sk = i.i_item_sk
WHERE d.d_year = 1998
  AND d.d_same_day_ly = 2414675
  AND c.c_birth_year = 1977
  AND i.i_brand = 'BrandX'
  AND cr.cr_return_ship_cost > 1000.00
GROUP BY d.d_year, cc.cc_name, r.r_reason_desc, i.i_brand, cp.cp_department
ORDER BY total_sales_net_paid DESC
LIMIT 100
