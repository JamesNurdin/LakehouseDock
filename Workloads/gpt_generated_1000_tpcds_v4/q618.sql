WITH sales_inventory_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_state,
        cs.cs_item_sk,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity,
        AVG(cs.cs_list_price) AS avg_list_price,
        SUM(inv.inv_quantity_on_hand) AS total_on_hand
    FROM catalog_sales cs
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cs.cs_list_price BETWEEN 90 AND 200
      AND cs.cs_ext_discount_amt > 1000
      AND cs.cs_quantity > 0
      AND w.w_zip IN ('35709', '58828', '19231')
      AND w.w_street_type IN ('Dr.', 'Wy', 'Ave')
      AND inv.inv_item_sk IN (10, 22, 34)
      AND inv.inv_date_sk = 2450822
    GROUP BY w.w_warehouse_id, w.w_state, cs.cs_item_sk
),
state_sales_stats AS (
    SELECT
        w_state,
        AVG(total_sales) AS avg_sales_per_item,
        SUM(total_quantity) AS sum_quantity_state
    FROM sales_inventory_agg
    GROUP BY w_state
    HAVING AVG(total_sales) > 5000
)
SELECT
    a.w_warehouse_id,
    a.w_state,
    a.cs_item_sk,
    a.total_sales,
    a.total_quantity,
    a.avg_list_price,
    a.total_on_hand,
    s.avg_sales_per_item,
    ROW_NUMBER() OVER (PARTITION BY a.w_state ORDER BY a.total_sales DESC) AS sales_rank_state
FROM sales_inventory_agg a
JOIN state_sales_stats s
    ON a.w_state = s.w_state
ORDER BY a.w_state, sales_rank_state
LIMIT 100
