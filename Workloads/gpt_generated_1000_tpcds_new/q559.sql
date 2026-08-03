WITH reason_agg AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc,
        COUNT(DISTINCT cr.cr_order_number)                     AS catalog_order_cnt,
        SUM(DISTINCT cr.cr_return_amount)                     AS catalog_return_amt_distinct,
        COUNT(DISTINCT sr.sr_ticket_number)                  AS store_ticket_cnt,
        SUM(DISTINCT sr.sr_return_amt)                       AS store_return_amt_distinct
    FROM reason r
    LEFT JOIN catalog_returns cr ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_returns sr   ON sr.sr_reason_sk = r.r_reason_sk
    GROUP BY r.r_reason_sk, r.r_reason_desc
),
volume_category AS (
    SELECT
        r_reason_sk,
        CASE
            WHEN catalog_order_cnt > 200 THEN 'HIGH'
            WHEN catalog_order_cnt > 50  THEN 'MEDIUM'
            ELSE 'LOW'
        END                                              AS order_volume,
        catalog_return_amt_distinct,
        store_return_amt_distinct
    FROM reason_agg
),
small_dim AS (
    SELECT r_reason_sk
    FROM reason
    WHERE r_reason_sk IN (1, 3, 5, 9, 13, 16)
),
computed AS (
    SELECT
        sd.r_reason_sk,
        vc.order_volume,
        vc.catalog_return_amt_distinct,
        vc.store_return_amt_distinct
    FROM small_dim sd
    CROSS JOIN volume_category vc
    WHERE sd.r_reason_sk = vc.r_reason_sk
)
/*
   First set: high‑volume reasons that also have a large distinct catalog return amount.
   Subtract any low‑volume reasons.
   Then union a medium‑volume slice.
*/
(
    SELECT
        c.r_reason_sk,
        c.order_volume,
        c.catalog_return_amt_distinct,
        c.store_return_amt_distinct,
        'HIGH_VOLUME' AS segment
    FROM computed c
    WHERE c.order_volume = 'HIGH'
)
INTERSECT
(
    SELECT
        c.r_reason_sk,
        c.order_volume,
        c.catalog_return_amt_distinct,
        c.store_return_amt_distinct,
        'HIGH_VOLUME' AS segment
    FROM computed c
    WHERE c.catalog_return_amt_distinct > 500
)
EXCEPT
(
    SELECT
        c.r_reason_sk,
        c.order_volume,
        c.catalog_return_amt_distinct,
        c.store_return_amt_distinct,
        'HIGH_VOLUME' AS segment
    FROM computed c
    WHERE c.order_volume = 'LOW'
)
UNION ALL
(
    SELECT
        c.r_reason_sk,
        c.order_volume,
        c.catalog_return_amt_distinct,
        c.store_return_amt_distinct,
        'MEDIUM_VOLUME' AS segment
    FROM computed c
    WHERE c.order_volume = 'MEDIUM'
)
ORDER BY r_reason_sk
LIMIT 100
