WITH base AS (
    SELECT
        sr.sr_item_sk,
        i.i_brand,
        i.i_category,
        r.r_reason_desc,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_return_quantity) AS total_qty,
        COUNT(*) AS cnt
    FROM tpcds.store_returns sr
    TABLESAMPLE BERNOULLI (10)
    FULL OUTER JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    LEFT JOIN tpcds.item i
        ON sr.sr_item_sk = i.i_item_sk
    WHERE
        sr.sr_return_quantity > 5
        AND sr.sr_return_amt > 20.00
        AND i.i_brand_id IN (1, 2, 3)
        AND i.i_category_id BETWEEN 2 AND 5
        AND r.r_reason_id LIKE 'AAAAAAA%'
        AND sr.sr_return_tax IS NOT NULL
    GROUP BY CUBE (sr.sr_item_sk, i.i_brand, i.i_category, r.r_reason_desc)
),
agg1 AS (
    SELECT
        sr_item_sk,
        i_brand,
        i_category,
        r_reason_desc,
        total_return_amt,
        total_qty,
        cnt,
        total_return_amt / NULLIF(cnt, 0) AS avg_return_per_tx
    FROM base
    WHERE total_qty > 10
),
agg2 AS (
    SELECT
        NULL AS sr_item_sk,
        'ALL' AS i_brand,
        NULL AS i_category,
        'All Reasons' AS r_reason_desc,
        SUM(total_return_amt) AS total_return_amt,
        SUM(total_qty) AS total_qty,
        SUM(cnt) AS cnt,
        SUM(total_return_amt) / NULLIF(SUM(cnt), 0) AS avg_return_per_tx
    FROM base
)
SELECT *
FROM (
    SELECT * FROM agg1
    UNION DISTINCT
    SELECT * FROM agg2
) u
ORDER BY avg_return_per_tx DESC
OFFSET 10 LIMIT 100
