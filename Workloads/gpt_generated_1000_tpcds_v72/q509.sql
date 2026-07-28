WITH catalog_ret AS (
    SELECT
        c.c_customer_id,
        cr.cr_return_amount        AS return_amount,
        r.r_reason_desc           AS reason_desc,
        sm.sm_type                AS ship_type,
        'Catalog'                 AS source
    FROM catalog_returns cr
    JOIN customer c
        ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE cr.cr_return_amount > 100
      AND LOWER(r.r_reason_desc) LIKE '%damaged%'
),
web_ret AS (
    SELECT
        c.c_customer_id,
        wr.wr_return_amt          AS return_amount,
        r.r_reason_desc           AS reason_desc,
        sm.sm_type                AS ship_type,
        'Web'                     AS source
    FROM web_returns wr
    JOIN customer c
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk      = ws.ws_item_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE wr.wr_return_amt > 100
      AND LOWER(r.r_reason_desc) LIKE '%damaged%'
)
SELECT *
FROM catalog_ret
UNION ALL
SELECT *
FROM web_ret
ORDER BY source, return_amount DESC
