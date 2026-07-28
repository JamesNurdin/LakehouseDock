WITH cs_agg AS (
    SELECT
        cs_warehouse_sk,
        cs_sold_date_sk,
        SUM(cs_ext_sales_price) AS cs_sales,
        SUM(cs_net_profit) AS cs_profit
    FROM catalog_sales
    WHERE cs_ext_ship_cost > 100
    GROUP BY cs_warehouse_sk, cs_sold_date_sk
),
ws_agg AS (
    SELECT
        ws_warehouse_sk,
        ws_sold_date_sk,
        SUM(ws_ext_sales_price) AS ws_sales,
        SUM(ws_net_profit) AS ws_profit
    FROM web_sales
    WHERE ws_ext_ship_cost > 50
    GROUP BY ws_warehouse_sk, ws_sold_date_sk
),
inv_agg AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand
    FROM inventory
    WHERE inv_quantity_on_hand > 0
    GROUP BY inv_warehouse_sk, inv_date_sk
),
combined AS (
    SELECT
        COALESCE(cs.cs_warehouse_sk, ws.ws_warehouse_sk, inv.inv_warehouse_sk) AS warehouse_sk,
        COALESCE(cs.cs_sold_date_sk, ws.ws_sold_date_sk, inv.inv_date_sk) AS date_sk,
        cs.cs_sales,
        cs.cs_profit,
        ws.ws_sales,
        ws.ws_profit,
        inv.total_quantity_on_hand
    FROM cs_agg cs
    FULL OUTER JOIN ws_agg ws
        ON cs.cs_warehouse_sk = ws.ws_warehouse_sk
        AND cs.cs_sold_date_sk = ws.ws_sold_date_sk
    FULL OUTER JOIN inv_agg inv
        ON COALESCE(cs.cs_warehouse_sk, ws.ws_warehouse_sk) = inv.inv_warehouse_sk
        AND COALESCE(cs.cs_sold_date_sk, ws.ws_sold_date_sk) = inv.inv_date_sk
)
SELECT
    w.w_warehouse_name,
    d.d_year,
    SUM(COALESCE(combined.cs_sales, 0) + COALESCE(combined.ws_sales, 0)) AS total_sales,
    SUM(COALESCE(combined.cs_profit, 0) + COALESCE(combined.ws_profit, 0)) AS total_profit,
    SUM(COALESCE(combined.total_quantity_on_hand, 0)) AS total_quantity_on_hand,
    CASE
        WHEN SUM(COALESCE(combined.cs_profit, 0) + COALESCE(combined.ws_profit, 0)) > 100000 THEN 'High'
        ELSE 'Low'
    END AS profit_category,
    RANK() OVER (
        PARTITION BY w.w_warehouse_name
        ORDER BY SUM(COALESCE(combined.cs_sales, 0) + COALESCE(combined.ws_sales, 0)) DESC
    ) AS sales_rank
FROM combined
JOIN warehouse w
    ON w.w_warehouse_sk = combined.warehouse_sk
JOIN date_dim d
    ON d.d_date_sk = combined.date_sk
WHERE w.w_country = 'United States'
  AND d.d_year BETWEEN 1998 AND 2000
  AND w.w_city IS NOT NULL
  AND w.w_state <> ''
GROUP BY GROUPING SETS (
    (w.w_warehouse_name, d.d_year),
    (w.w_warehouse_name),
    (d.d_year)
)
ORDER BY total_sales DESC, w.w_warehouse_name
LIMIT 100
