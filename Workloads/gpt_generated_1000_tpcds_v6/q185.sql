WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_net_paid,
    cs.cs_net_profit,
    cs.cs_quantity,
    i.i_item_id,
    i.i_brand,
    i.i_category,
    c.c_customer_id,
    c.c_last_name,
    cc.cc_call_center_id,
    cc.cc_state,
    cp.cp_department,
    w.w_warehouse_id,
    w.w_state,
    inv.inv_quantity_on_hand,
    inv.inv_date_sk,
    wp.wp_type
  FROM catalog_sales cs
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
  WHERE cc.cc_state = 'CA'
    AND w.w_state = 'CA'
    AND i.i_brand = 'Brand#12'
    AND c.c_last_name = 'White'
    AND cp.cp_department = 'Sports'
    AND inv.inv_quantity_on_hand > 100
    AND cs.cs_net_profit > 0
    AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2450948
),
returns AS (
  SELECT
    cr.cr_order_number,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt
  FROM catalog_returns cr
  WHERE cr.cr_return_quantity > 0
  GROUP BY cr.cr_order_number
),
agg_per_item AS (
  SELECT
    b.i_item_id,
    b.i_brand,
    b.i_category,
    SUM(b.cs_net_paid) AS sum_net_paid,
    SUM(b.cs_net_profit) AS sum_net_profit,
    SUM(COALESCE(r.total_return_amount, 0)) AS sum_return_amount,
    COUNT(*) AS sales_transactions,
    MAX(b.inv_quantity_on_hand) AS max_inventory,
    COUNT(DISTINCT b.c_customer_id) AS distinct_customers
  FROM base b
  LEFT JOIN returns r ON b.cs_order_number = r.cr_order_number
  GROUP BY b.i_item_id, b.i_brand, b.i_category
),
final AS (
  SELECT
    i_item_id,
    i_brand,
    i_category,
    sum_net_paid,
    sum_net_profit,
    sum_return_amount,
    sales_transactions,
    max_inventory,
    distinct_customers,
    (sum_net_profit - sum_return_amount) AS net_profit_after_returns,
    (sum_net_profit - sum_return_amount) / NULLIF(sales_transactions, 0) AS avg_profit_per_sale
  FROM agg_per_item
  WHERE max_inventory > 200
    AND distinct_customers >= 5
)
SELECT
  f.i_item_id,
  f.i_brand,
  f.i_category,
  f.sum_net_paid,
  f.net_profit_after_returns,
  f.avg_profit_per_sale,
  (
    SELECT COUNT(*)
    FROM agg_per_item a
    WHERE a.sum_net_profit > f.sum_net_profit
  ) AS higher_profit_item_count
FROM final f
ORDER BY f.net_profit_after_returns DESC
LIMIT 100
