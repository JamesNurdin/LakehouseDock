WITH sales_agg AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_manager,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    i.i_category,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid,
    SUM(cs.cs_coupon_amt) AS total_coupon,
    AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty
  FROM call_center cc
  JOIN catalog_sales cs ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                     AND inv.inv_date_sk = d.d_date_sk
  WHERE cc.cc_manager = 'Larry Mccray'
    AND cs.cs_coupon_amt > 500
    AND cs.cs_net_paid_inc_tax >= 1000
    AND d.d_year = 2001
    AND i.i_category = 'Electronics'
    AND inv.inv_quantity_on_hand > 300
  GROUP BY
    cc.cc_call_center_sk,
    cc.cc_name,
    cc.cc_manager,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    d.d_year,
    i.i_category
)
SELECT
  cc_name,
  cc_manager,
  c_first_name,
  c_last_name,
  d_year,
  i_category,
  total_net_paid,
  total_coupon,
  avg_inventory_qty,
  RANK() OVER (PARTITION BY cc_name ORDER BY total_net_paid DESC) AS sales_rank_by_center,
  CASE
    WHEN total_net_paid > 5000 THEN 'High'
    WHEN total_net_paid > 2000 THEN 'Medium'
    ELSE 'Low'
  END AS sales_volume_category
FROM sales_agg
ORDER BY cc_name, sales_rank_by_center
LIMIT 100
