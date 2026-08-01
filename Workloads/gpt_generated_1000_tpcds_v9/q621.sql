WITH store_return_stats AS (
    SELECT sr.sr_item_sk,
           SUM(sr.sr_return_quantity) AS total_return_quantity
    FROM store_returns sr
    JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
    WHERE td.t_minute IN (4, 6, 9)
    GROUP BY sr.sr_item_sk
)
SELECT
    ud.i_item_sk,
    ud.i_product_name,
    ud.channel,
    ud.net_paid,
    ud.orders,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity
FROM (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        'catalog' AS channel,
        SUM(cs.cs_net_paid) AS net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS orders
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_minute IN (4, 6, 9)
      AND td.t_second < 15
    GROUP BY i.i_item_sk, i.i_product_name

    UNION ALL

    SELECT
        i.i_item_sk,
        i.i_product_name,
        'web' AS channel,
        SUM(ws.ws_net_paid) AS net_paid,
        COUNT(DISTINCT ws.ws_order_number) AS orders
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    WHERE td.t_minute IN (4, 6, 9)
      AND td.t_second < 15
    GROUP BY i.i_item_sk, i.i_product_name
) AS ud
LEFT JOIN store_return_stats r ON ud.i_item_sk = r.sr_item_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_item_sk = ud.i_item_sk
)
ORDER BY ud.net_paid DESC
LIMIT 100
