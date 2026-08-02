WITH catalog_ret AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        i.i_item_id,
        i.i_item_desc,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_transactions,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    WHERE cr.cr_return_amount > 50
    GROUP BY cr.cr_item_sk, i.i_item_id, i.i_item_desc
),
web_ret AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        i.i_item_id,
        i.i_item_desc,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_transactions,
        'web' AS source
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    WHERE wr.wr_return_amt > 30
    GROUP BY ws.ws_item_sk, i.i_item_id, i.i_item_desc
),
combined_returns AS (
    SELECT * FROM catalog_ret
    UNION ALL
    SELECT * FROM web_ret
)
SELECT
    cr.item_sk,
    cr.i_item_id,
    cr.i_item_desc,
    cr.source,
    cr.total_return_qty,
    cr.total_return_amount,
    cr.return_transactions,
    ROW_NUMBER() OVER (PARTITION BY cr.source ORDER BY cr.total_return_amount DESC) AS rank_by_amount,
    (
        SELECT AVG(cr2.total_return_amount)
        FROM catalog_ret cr2
        WHERE cr2.item_sk = cr.item_sk
    ) AS avg_catalog_return_amount,
    promo.p_promo_name,
    promo.p_discount_active
FROM combined_returns cr
CROSS JOIN LATERAL (
    SELECT p.p_promo_name, p.p_discount_active
    FROM promotion p
    WHERE p.p_item_sk = cr.item_sk
    ORDER BY p.p_start_date_sk DESC
    LIMIT 1
) AS promo
WHERE cr.total_return_amount > 0
ORDER BY cr.total_return_amount DESC
LIMIT 100
