WITH base AS (
    SELECT
        r.r_reason_desc,
        w.w_warehouse_name,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        wr.wr_return_amt,
        wr.wr_return_quantity
    FROM reason r
    JOIN catalog_returns cr
        ON cr.cr_reason_sk = r.r_reason_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%model%'
      AND w.w_county = 'Walker County'
      AND cr.cr_return_quantity >= 2
      AND wr.wr_return_quantity > 0
),

catalog_agg AS (
    SELECT
        r_reason_desc,
        w_warehouse_name,
        'catalog' AS source,
        SUM(cr_return_amount) AS total_amount,
        COUNT(*) AS transaction_cnt
    FROM base
    GROUP BY ROLLUP (r_reason_desc, w_warehouse_name)
),

web_agg AS (
    SELECT
        r_reason_desc,
        w_warehouse_name,
        'web' AS source,
        SUM(wr_return_amt) AS total_amount,
        COUNT(*) AS transaction_cnt
    FROM base
    GROUP BY ROLLUP (r_reason_desc, w_warehouse_name)
),

combined AS (
    SELECT
        r_reason_desc,
        COALESCE(w_warehouse_name, 'ALL WAREHOUSES') AS warehouse_name,
        source,
        total_amount,
        transaction_cnt,
        RANK() OVER (PARTITION BY r_reason_desc, source ORDER BY total_amount DESC) AS amount_rank,
        CASE
            WHEN total_amount >= 5000 THEN 'HIGH'
            WHEN total_amount >= 1000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS amount_category
    FROM (
        SELECT * FROM catalog_agg
        UNION ALL
        SELECT * FROM web_agg
    ) u
)

SELECT
    r_reason_desc,
    warehouse_name,
    source,
    total_amount,
    transaction_cnt,
    amount_rank,
    amount_category,
    DENSE_RANK() OVER (ORDER BY total_amount DESC) AS overall_rank
FROM combined
ORDER BY r_reason_desc, source, overall_rank
