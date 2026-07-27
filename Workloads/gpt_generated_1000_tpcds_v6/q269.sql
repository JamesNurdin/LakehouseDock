WITH inventory_latest AS (
    SELECT DISTINCT inv_item_sk, inv_quantity_on_hand
    FROM inventory
    WHERE inv_date_sk = 2450829
),
sales_agg AS (
    SELECT
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_item_sk,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_net_profit) AS avg_profit,
        COUNT(DISTINCT cs.cs_order_number) AS distinct_orders
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450820 AND 2450900
      AND cs.cs_quantity > 1
      AND cs.cs_coupon_amt > 0
      AND cs.cs_net_paid_inc_tax > 300
      AND cs.cs_ship_cdemo_sk IN (90299, 1046123)
      AND cs.cs_ship_mode_sk IS NOT NULL
    GROUP BY cs.cs_catalog_page_sk, cs.cs_ship_mode_sk, cs.cs_item_sk
)
SELECT
    cp.cp_catalog_page_id,
    cp.cp_department,
    sm.sm_type,
    i.i_brand,
    i.i_category,
    COALESCE(inv_latest.inv_quantity_on_hand, 0) AS quantity_on_hand,
    sa.total_quantity,
    sa.total_sales,
    sa.avg_profit,
    sa.distinct_orders
FROM sales_agg sa
JOIN catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm ON sa.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN item i ON sa.cs_item_sk = i.i_item_sk
LEFT JOIN inventory_latest inv_latest ON i.i_item_sk = inv_latest.inv_item_sk
WHERE sm.sm_type = 'REGULAR'
  AND i.i_brand = 'Brand#12'
  AND i.i_category = 'Electronics'
ORDER BY sa.total_sales DESC
LIMIT 100
