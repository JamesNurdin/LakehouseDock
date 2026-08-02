WITH item_promotions AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           array_agg(p.p_promo_id) AS promo_ids
    FROM item i
    LEFT JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, i.i_item_id
),
expanded_promos AS (
    SELECT ip.i_item_sk,
           ip.i_item_id,
           promo_id
    FROM item_promotions ip
    CROSS JOIN UNNEST(ip.promo_ids) AS t(promo_id)
),
store_returns_agg AS (
    SELECT
        'store' AS return_source,
        i.i_item_id AS item_id,
        s.s_store_name AS location_name,
        d.d_date AS return_date,
        sr.sr_return_quantity AS return_quantity,
        sr.sr_net_loss AS net_loss,
        SUM(sr.sr_net_loss) OVER (
            PARTITION BY s.s_store_name
            ORDER BY d.d_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_net_loss,
        (SELECT i2.i_current_price FROM item i2 WHERE i2.i_item_sk = sr.sr_item_sk) AS current_price,
        CASE WHEN EXISTS (SELECT 1 FROM expanded_promos ep WHERE ep.i_item_sk = sr.sr_item_sk) THEN 'Y' ELSE 'N' END AS has_promo
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
),
catalog_returns_agg AS (
    SELECT
        'catalog' AS return_source,
        i.i_item_id AS item_id,
        w.w_warehouse_name AS location_name,
        d.d_date AS return_date,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_net_loss AS net_loss,
        SUM(cr.cr_net_loss) OVER (
            PARTITION BY w.w_warehouse_name
            ORDER BY d.d_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_net_loss,
        (SELECT i2.i_current_price FROM item i2 WHERE i2.i_item_sk = cr.cr_item_sk) AS current_price,
        CASE WHEN EXISTS (SELECT 1 FROM expanded_promos ep WHERE ep.i_item_sk = cr.cr_item_sk) THEN 'Y' ELSE 'N' END AS has_promo
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
)
SELECT
    return_source,
    item_id,
    location_name,
    return_date,
    return_quantity,
    net_loss,
    cumulative_net_loss,
    current_price,
    has_promo
FROM store_returns_agg
UNION ALL
SELECT
    return_source,
    item_id,
    location_name,
    return_date,
    return_quantity,
    net_loss,
    cumulative_net_loss,
    current_price,
    has_promo
FROM catalog_returns_agg
LIMIT 100
