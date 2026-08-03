WITH sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(ss.ss_net_paid) AS total_amount,
        'SALE' AS transaction_type,
        CASE WHEN SUM(ss.ss_net_paid) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS amount_sign
    FROM
        store_sales ss
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE
        p.p_channel_event = 'N'
        AND ss.ss_sold_date_sk BETWEEN 2450815 AND 2450825
    GROUP BY
        i.i_item_id,
        i.i_product_name
),
returns_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        SUM(cr.cr_return_amount) AS total_amount,
        'RETURN' AS transaction_type,
        CASE WHEN SUM(cr.cr_return_amount) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS amount_sign
    FROM
        catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE
        sm.sm_type = 'AIR'
        AND w.w_state = 'CA'
        AND cr.cr_returned_date_sk BETWEEN 2450815 AND 2450825
    GROUP BY
        i.i_item_id,
        i.i_product_name
)
SELECT
    i_item_id,
    i_product_name,
    total_amount,
    transaction_type,
    amount_sign
FROM sales_agg
UNION ALL
SELECT
    i_item_id,
    i_product_name,
    total_amount,
    transaction_type,
    amount_sign
FROM returns_agg
LIMIT 100
