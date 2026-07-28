/*
Goal: Compare yearly sales and profit performance of promotional campaigns that are marked as an event (p_channel_event = 'Y') across catalog and web channels, showing total sales, total profit, a profit status flag, and the average profit for the year. The results from both channels are combined with UNION ALL, ordered, and limited.
*/
WITH promo_cte AS (
    SELECT p_promo_sk,
           p_promo_name,
           p_channel_event
    FROM promotion
    WHERE p_channel_event = 'Y'
)
SELECT
    d.d_year AS year,
    pc.p_promo_name AS promo_name,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    CASE WHEN SUM(cs.cs_net_profit) >= 0 THEN 'Positive' ELSE 'Negative' END AS profit_status,
    (
        SELECT AVG(cs_inner.cs_net_profit)
        FROM catalog_sales cs_inner
        JOIN date_dim d_inner ON cs_inner.cs_sold_date_sk = d_inner.d_date_sk
        WHERE d_inner.d_year = d.d_year
    ) AS avg_catalog_profit
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN promo_cte pc ON cs.cs_promo_sk = pc.p_promo_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, pc.p_promo_name, pc.p_promo_sk
HAVING SUM(cs.cs_ext_sales_price) > 1000

UNION ALL

SELECT
    d.d_year AS year,
    pc.p_promo_name AS promo_name,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    CASE WHEN SUM(ws.ws_net_profit) >= 0 THEN 'Positive' ELSE 'Negative' END AS profit_status,
    (
        SELECT AVG(ws_inner.ws_net_profit)
        FROM web_sales ws_inner
        JOIN date_dim d_inner ON ws_inner.ws_sold_date_sk = d_inner.d_date_sk
        WHERE d_inner.d_year = d.d_year
    ) AS avg_web_profit
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN promo_cte pc ON ws.ws_promo_sk = pc.p_promo_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year, pc.p_promo_name, pc.p_promo_sk
HAVING SUM(ws.ws_ext_sales_price) > 1000
ORDER BY year DESC, total_sales DESC
LIMIT 100
