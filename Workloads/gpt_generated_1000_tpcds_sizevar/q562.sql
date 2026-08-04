WITH cc_sales AS (
   SELECT
       cc.cc_call_center_sk,
       cc.cc_name,
       cc.cc_state,
       cs.cs_order_number,
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_quantity,
       cs.cs_sales_price,
       cs.cs_warehouse_sk,
       cs.cs_item_sk,
       cs.cs_bill_cdemo_sk
   FROM call_center cc
   FULL OUTER JOIN catalog_sales cs
       ON cc.cc_call_center_sk = cs.cs_call_center_sk
   WHERE cc.cc_state = 'CA'
     AND (cs.cs_quantity > 0 OR cs.cs_quantity IS NULL)
),
sales_returns AS (
   SELECT
       cs.cs_order_number,
       cs.cs_sold_date_sk,
       cs.cs_sold_time_sk,
       cs.cs_quantity,
       cs.cs_sales_price,
       cs.cs_warehouse_sk,
       cs.cs_bill_cdemo_sk,
       d.d_year,
       t.t_hour,
       cd.cd_gender,
       w.w_warehouse_name,
       w.w_country,
       cr.cr_return_amount,
       r.r_reason_desc
   FROM cc_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
   JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
   LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
   WHERE d.d_year BETWEEN 1998 AND 2001
     AND t.t_hour BETWEEN 8 AND 18
     AND w.w_country = 'United States'
     AND cd.cd_gender = 'M'
),
inventory_info AS (
   SELECT
       inv.inv_warehouse_sk,
       inv.inv_date_sk,
       inv.inv_quantity_on_hand,
       d.d_year AS inv_year,
       w.w_warehouse_name
   FROM inventory inv
   JOIN date_dim d ON inv.inv_date_sk = d.d_date_sk
   JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   WHERE inv.inv_quantity_on_hand > 0
),
order_keys AS (
   SELECT cs_order_number FROM catalog_sales
),
return_keys AS (
   SELECT cr_order_number FROM catalog_returns
),
common_orders AS (
   SELECT cs_order_number FROM order_keys
   INTERSECT
   SELECT cr_order_number FROM return_keys
)
SELECT
   COALESCE(s.d_year, i.inv_year) AS year,
   SUM(s.sales_amount) AS total_sales,
   SUM(s.return_amount) AS total_return,
   COUNT(*) AS transaction_cnt,
   SUM(SUM(s.sales_amount)) OVER (
       PARTITION BY COALESCE(s.d_year, i.inv_year)
       ORDER BY COALESCE(s.d_year, i.inv_year)
       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
   ) AS running_sum_sales
FROM (
   SELECT
       sr.d_year,
       sr.cs_order_number,
       sr.cs_quantity * sr.cs_sales_price AS sales_amount,
       COALESCE(sr.cr_return_amount, 0) AS return_amount
   FROM sales_returns sr
   WHERE sr.cs_order_number IN (SELECT cs_order_number FROM common_orders)
) s
FULL OUTER JOIN (
   SELECT
       inv_year,
       SUM(inv_quantity_on_hand) AS inv_qty
   FROM inventory_info
   GROUP BY inv_year
) i
   ON s.d_year = i.inv_year
WHERE (SELECT MIN(d_year) FROM date_dim WHERE d_year >= 1998) = 1998
GROUP BY CUBE(s.d_year, i.inv_year)
HAVING SUM(s.sales_amount) > 50000
ORDER BY total_sales DESC
LIMIT 100
