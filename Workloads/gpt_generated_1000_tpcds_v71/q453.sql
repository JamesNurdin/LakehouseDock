WITH unified_sales AS (
    -- Catalog channel sales with active promotion
    SELECT
        i.i_item_sk,
        i.i_item_id,
        d.d_date,
        cs.cs_net_paid AS net_paid,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
          AND p.p_start_date_sk <= d.d_date_sk
          AND p.p_end_date_sk   >= d.d_date_sk
    )
    UNION ALL
    -- Web channel sales with active promotion
    SELECT
        i.i_item_sk,
        i.i_item_id,
        d.d_date,
        ws.ws_net_paid AS net_paid,
        'web' AS channel
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_item_sk = i.i_item_sk
          AND p.p_start_date_sk <= d.d_date_sk
          AND p.p_end_date_sk   >= d.d_date_sk
    )
)
SELECT
    us.i_item_id,
    us.d_date,
    SUM(us.net_paid) AS total_net_paid,
    us.channel,
    (
        SELECT AVG(cs_inner.cs_net_paid)
        FROM catalog_sales cs_inner
        WHERE cs_inner.cs_item_sk = us.i_item_sk
    ) AS avg_catalog_net_paid
FROM unified_sales us
GROUP BY
    us.i_item_id,
    us.d_date,
    us.channel,
    us.i_item_sk
HAVING SUM(us.net_paid) > 1000
ORDER BY total_net_paid DESC
LIMIT 100
