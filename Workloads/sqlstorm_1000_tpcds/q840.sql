WITH channel_sales AS (
    SELECT 'store' AS channel, ss.ss_sold_date_sk AS date_sk, ss.ss_item_sk AS item_sk, ss.ss_net_paid AS net_paid
    FROM store_sales ss
    UNION ALL
    SELECT 'catalog' AS channel, cs.cs_sold_date_sk, cs.cs_item_sk, cs.cs_net_paid
    FROM catalog_sales cs
    UNION ALL
    SELECT 'web' AS channel, ws.ws_sold_date_sk, ws.ws_item_sk, ws.ws_net_paid
    FROM web_sales ws
)
SELECT
    d.d_year,
    d.d_moy,
    i.i_category,
    cs.channel,
    sum(cs.net_paid) AS total_net_paid,
    avg(cs.net_paid) AS avg_net_paid,
    count(*) AS sales_count
FROM channel_sales cs
JOIN date_dim d ON cs.date_sk = d.d_date_sk
JOIN item i ON cs.item_sk = i.i_item_sk
WHERE d.d_year BETWEEN 1999 AND 2000
GROUP BY d.d_year, d.d_moy, i.i_category, cs.channel
ORDER BY total_net_paid DESC
LIMIT 200
