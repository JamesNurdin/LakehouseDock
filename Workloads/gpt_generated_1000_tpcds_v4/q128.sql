WITH store_ret AS (
    SELECT DISTINCT
        c.c_customer_id,
        'store' AS return_source,
        (
            SELECT SUM(ss.ss_net_paid)
            FROM store_sales ss
            WHERE ss.ss_customer_sk = c.c_customer_sk
        ) AS total_sales_amount
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE r.r_reason_desc = 'Damaged'
      AND sr.sr_net_loss > 100
      AND i.i_category = 'Sports'
),
catalog_ret AS (
    SELECT DISTINCT
        c.c_customer_id,
        'catalog' AS return_source,
        (
            SELECT SUM(ss.ss_net_paid)
            FROM store_sales ss
            WHERE ss.ss_customer_sk = c.c_customer_sk
        ) AS total_sales_amount
    FROM catalog_returns cr
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE r.r_reason_desc = 'Damaged'
      AND cr.cr_return_amount > 200
      AND i.i_category = 'Sports'
)
SELECT
    u.c_customer_id AS customer_id,
    u.return_source,
    u.total_sales_amount
FROM (
    SELECT * FROM store_ret
    UNION ALL
    SELECT * FROM catalog_ret
) u
ORDER BY u.total_sales_amount DESC NULLS LAST
LIMIT 100
