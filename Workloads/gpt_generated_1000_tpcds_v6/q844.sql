WITH agg_sales AS (
    SELECT
        w.w_state,
        w.w_city,
        i.inv_item_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        SUM(cs.cs_net_profit) AS total_profit
    FROM catalog_sales cs
    JOIN customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory i
        ON w.w_warehouse_sk = i.inv_warehouse_sk
    WHERE cs.cs_ext_wholesale_cost > 2000
      AND cs.cs_ext_ship_cost < 1000
      AND w.w_street_name LIKE '%Center%'
      AND i.inv_quantity_on_hand > 0
    GROUP BY ROLLUP (w.w_state, w.w_city, i.inv_item_sk)
),

sales_filtered AS (
    SELECT
        w_state,
        w_city,
        inv_item_sk,
        total_sales,
        CASE
            WHEN total_sales > 100000 THEN 'High'
            WHEN total_sales > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM agg_sales
    WHERE w_state = 'TX'
),

sales_other AS (
    SELECT
        w_state,
        w_city,
        inv_item_sk,
        total_sales,
        CASE
            WHEN total_sales > 100000 THEN 'High'
            WHEN total_sales > 50000 THEN 'Medium'
            ELSE 'Low'
        END AS sales_category
    FROM agg_sales
    WHERE w_state = 'CA'
)
SELECT
    combined.w_state,
    combined.w_city,
    combined.inv_item_sk,
    combined.total_sales,
    combined.sales_category,
    ROW_NUMBER() OVER (PARTITION BY combined.w_state ORDER BY combined.total_sales DESC) AS rn
FROM (
    SELECT * FROM sales_filtered
    UNION ALL
    SELECT * FROM sales_other
) AS combined
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory i_zero
    WHERE i_zero.inv_item_sk = combined.inv_item_sk
      AND i_zero.inv_quantity_on_hand = 0
)
ORDER BY rn
LIMIT 100
