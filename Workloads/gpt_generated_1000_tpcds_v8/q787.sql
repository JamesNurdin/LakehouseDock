WITH sampled_sales AS (
    SELECT cs_sold_date_sk,
           cs_sold_time_sk,
           cs_warehouse_sk,
           cs_item_sk,
           cs_order_number,
           cs_net_profit
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
sales_with_inventory AS (
    SELECT cs.cs_order_number,
           cs.cs_item_sk,
           cs.cs_net_profit,
           CASE WHEN cs.cs_net_profit > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag,
           w.w_county,
           inv.inv_quantity_on_hand,
           inv_sum.total_qty
    FROM sampled_sales cs
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_item_sk = cs.cs_item_sk
       AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN LATERAL (
        SELECT SUM(i.inv_quantity_on_hand) AS total_qty
        FROM inventory i
        WHERE i.inv_item_sk = cs.cs_item_sk
    ) inv_sum ON TRUE
    WHERE w.w_county = 'Marshall County'
)
SELECT order_number
FROM (
    SELECT cs_order_number AS order_number
    FROM sales_with_inventory
    WHERE profit_flag = 'POS'
    INTERSECT
    SELECT cs_order_number AS order_number
    FROM sales_with_inventory
    WHERE inv_quantity_on_hand > 500
) AS intersect_set
EXCEPT
SELECT cs_order_number
FROM sales_with_inventory
WHERE profit_flag = 'NEG'
LIMIT 100
