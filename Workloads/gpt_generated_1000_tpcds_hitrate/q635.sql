WITH sales_agg AS (
        SELECT 
            cs.cs_item_sk AS item_sk,
            'catalog' AS channel,
            cs.cs_sold_date_sk AS sold_date_sk,
            SUM(cs.cs_ext_sales_price) AS sales_amount,
            SUM(cs.cs_quantity) AS quantity_sold
        FROM catalog_sales cs
        JOIN item i ON cs.cs_item_sk = i.i_item_sk
        JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        WHERE t.t_meal_time = 'lunch'
        GROUP BY GROUPING SETS (
            (cs.cs_item_sk, cs.cs_sold_date_sk),
            (cs.cs_item_sk)
        )
    ),
    web_sales_agg AS (
        SELECT 
            ws.ws_item_sk AS item_sk,
            'web' AS channel,
            ws.ws_sold_date_sk AS sold_date_sk,
            SUM(ws.ws_ext_sales_price) AS sales_amount,
            SUM(ws.ws_quantity) AS quantity_sold
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        WHERE t.t_shift = 'first'
        GROUP BY GROUPING SETS (
            (ws.ws_item_sk, ws.ws_sold_date_sk),
            (ws.ws_item_sk)
        )
    ),
    combined_sales AS (
        SELECT * FROM sales_agg
        UNION ALL
        SELECT * FROM web_sales_agg
    )
SELECT
    cs.item_sk,
    i.i_product_name,
    cs.channel,
    COALESCE(cs.sold_date_sk, 0) AS sold_date_sk,
    cs.sales_amount,
    cs.quantity_sold,
    (
        SELECT SUM(inv_quantity_on_hand)
        FROM inventory inv
        WHERE inv.inv_item_sk = cs.item_sk
    ) AS total_inventory,
    RANK() OVER (PARTITION BY cs.channel ORDER BY cs.sales_amount DESC) AS sales_rank
FROM combined_sales cs
JOIN item i ON i.i_item_sk = cs.item_sk
WHERE EXISTS (
        SELECT 1
        FROM catalog_sales csc
        WHERE csc.cs_item_sk = cs.item_sk
          AND csc.cs_quantity > 0
    )
ORDER BY cs.sales_amount DESC, cs.item_sk
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
