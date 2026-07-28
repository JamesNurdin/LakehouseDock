WITH avg_all_sales AS (
    SELECT AVG(net_paid) AS avg_net_paid
    FROM (
        SELECT cs.cs_net_paid AS net_paid FROM catalog_sales cs
        UNION ALL
        SELECT ws.ws_net_paid AS net_paid FROM web_sales ws
    ) AS combined
)
SELECT
    d.d_year AS year,
    'Catalog' AS channel,
    SUM(cs.cs_net_paid) AS total_net_paid,
    SUM(cs.cs_quantity) AS total_quantity,
    a.avg_net_paid
FROM catalog_sales cs
JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
CROSS JOIN avg_all_sales a
WHERE d.d_year >= 2000
  AND p.p_channel_catalog = 'Y'
  AND p.p_item_sk = i.i_item_sk
GROUP BY d.d_year, a.avg_net_paid

UNION ALL

SELECT
    d.d_year AS year,
    'Web' AS channel,
    SUM(ws.ws_net_paid) AS total_net_paid,
    SUM(ws.ws_quantity) AS total_quantity,
    a.avg_net_paid
FROM web_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
CROSS JOIN avg_all_sales a
WHERE d.d_year >= 2000
  AND p.p_channel_catalog = 'Y'
  AND p.p_item_sk = i.i_item_sk
GROUP BY d.d_year, a.avg_net_paid

ORDER BY year, channel
