WITH promo_info AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_start_date_sk,
        p.p_end_date_sk
    FROM promotion p
    TABLESAMPLE BERNOULLI (10)
    JOIN date_dim d_start
        ON p.p_start_date_sk = d_start.d_date_sk
    WHERE d_start.d_year = 1998
)
SELECT
    promo_id,
    channel,
    total_sales_amount,
    avg_return_amount
FROM (
    SELECT
        p.p_promo_id AS promo_id,
        'catalog' AS channel,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        AVG(lr.avg_return_amount) AS avg_return_amount
    FROM catalog_sales cs
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN promo_info pi
        ON pi.p_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT AVG(cr.cr_return_amount) AS avg_return_amount
        FROM catalog_returns cr
        WHERE cr.cr_item_sk = cs.cs_item_sk
    ) lr
    WHERE d.d_year = 1998
    GROUP BY p.p_promo_id

    UNION ALL

    SELECT
        p.p_promo_id AS promo_id,
        'web' AS channel,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        AVG(lr.avg_return_amount) AS avg_return_amount
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN promo_info pi
        ON pi.p_promo_sk = p.p_promo_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    CROSS JOIN LATERAL (
        SELECT AVG(cr.cr_return_amount) AS avg_return_amount
        FROM catalog_returns cr
        JOIN item i
            ON cr.cr_item_sk = i.i_item_sk
        WHERE i.i_item_sk = ws.ws_item_sk
    ) lr
    WHERE d.d_year = 1998
    GROUP BY p.p_promo_id
) AS combined
ORDER BY promo_id, channel
LIMIT 100
