WITH sales_by_channel AS (
    SELECT
        'catalog' AS channel,
        i.i_brand AS brand,
        d.d_year AS year,
        SUM(cs.cs_net_profit) AS net_profit,
        CASE WHEN SUM(cs.cs_quantity) > 1000 THEN 'high volume' ELSE 'low volume' END AS volume_category
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY i.i_brand, d.d_year

    UNION ALL

    SELECT
        'web' AS channel,
        i.i_brand AS brand,
        d.d_year AS year,
        SUM(ws.ws_net_profit) AS net_profit,
        CASE WHEN SUM(ws.ws_quantity) > 1000 THEN 'high volume' ELSE 'low volume' END AS volume_category
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY i.i_brand, d.d_year
)
SELECT
    channel,
    brand,
    year,
    net_profit,
    volume_category
FROM sales_by_channel
ORDER BY channel, year DESC, net_profit DESC
LIMIT 100
