WITH avg_price_cte AS (
    SELECT AVG(i_current_price) AS avg_price
    FROM tpcds.item
)
SELECT *
FROM (
    SELECT
        i.i_item_id AS item_id,
        d.d_year AS year,
        'Catalog' AS channel,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS order_count,
        CASE WHEN SUM(cs.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND cs.cs_quantity > 0
    GROUP BY GROUPING SETS ((i.i_item_id, d.d_year), (i.i_item_id), (d.d_year))
    HAVING SUM(cs.cs_net_profit) > 1000

    UNION ALL

    SELECT
        i.i_item_id AS item_id,
        d.d_year AS year,
        'Web' AS channel,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(*) AS order_count,
        CASE
            WHEN SUM(ws.ws_net_profit) > (SELECT avg_price FROM avg_price_cte) * 10 THEN 'High'
            ELSE 'Low'
        END AS profit_category
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND ws.ws_quantity > 0
    GROUP BY GROUPING SETS ((i.i_item_id, d.d_year), (i.i_item_id), (d.d_year))
    HAVING SUM(ws.ws_net_profit) > 1000
) AS combined
ORDER BY total_net_profit DESC
LIMIT 100
