WITH sales_summary AS (
    SELECT
        s.s_store_id AS store_id,
        SUM(ws.ws_net_profit) AS total_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
    GROUP BY s.s_store_id
),
inventory_summary AS (
    SELECT
        s.s_store_id AS store_id,
        SUM(i.inv_quantity_on_hand) * -1 AS total_profit
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
      AND NOT EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_sold_date_sk = d.d_date_sk
      )
    GROUP BY s.s_store_id
),
combined AS (
    SELECT DISTINCT store_id, total_profit FROM sales_summary
    UNION ALL
    SELECT DISTINCT store_id, total_profit FROM inventory_summary
)
SELECT store_id,
       total_profit
FROM combined
ORDER BY total_profit DESC
LIMIT 100
