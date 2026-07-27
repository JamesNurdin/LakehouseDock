WITH year_2001_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2001
)
SELECT
    channel,
    i_item_id,
    i_product_name,
    total_sales,
    total_profit,
    avg_item_profit,
    profit_rank
FROM (
    SELECT
        'catalog' AS channel,
        i.i_item_id,
        i.i_product_name,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        (
            SELECT AVG(cs2.cs_net_profit)
            FROM catalog_sales cs2
            JOIN year_2001_dates yd2 ON cs2.cs_sold_date_sk = yd2.d_date_sk
            WHERE cs2.cs_item_sk = i.i_item_sk
        ) AS avg_item_profit,
        ROW_NUMBER() OVER (PARTITION BY 'catalog' ORDER BY SUM(cs.cs_net_profit) DESC) AS profit_rank
    FROM catalog_sales cs
    JOIN year_2001_dates yd ON cs.cs_sold_date_sk = yd.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE EXISTS (
        SELECT 1 FROM catalog_returns cr WHERE cr.cr_item_sk = i.i_item_sk
    )
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name

    UNION ALL

    SELECT
        'web' AS channel,
        i.i_item_id,
        i.i_product_name,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        (
            SELECT AVG(ws2.ws_net_profit)
            FROM web_sales ws2
            JOIN year_2001_dates yd2 ON ws2.ws_sold_date_sk = yd2.d_date_sk
            WHERE ws2.ws_item_sk = i.i_item_sk
        ) AS avg_item_profit,
        ROW_NUMBER() OVER (PARTITION BY 'web' ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM web_sales ws
    JOIN year_2001_dates yd ON ws.ws_sold_date_sk = yd.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE EXISTS (
        SELECT 1 FROM catalog_returns cr WHERE cr.cr_item_sk = i.i_item_sk
    )
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name
) combined
ORDER BY total_profit DESC
LIMIT 100
