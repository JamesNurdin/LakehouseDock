WITH sampled_cr AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (10) -- roughly 10% of rows for performance
),
joined_data AS (
    SELECT
        cp.cp_catalog_number,
        cp.cp_type,
        r.r_reason_desc,
        cr.cr_return_amount,
        cr.cr_return_amt_inc_tax,
        cr.cr_net_loss,
        sr.sr_return_quantity,
        sr.sr_net_loss,
        CASE WHEN cr.cr_return_amt_inc_tax > 1000 THEN 'High' ELSE 'Regular' END AS return_category,
        -- scalar subquery: average store net loss for the same reason
        (
            SELECT avg(sr2.sr_net_loss)
            FROM store_returns sr2
            WHERE sr2.sr_reason_sk = r.r_reason_sk
        ) AS avg_store_net_loss,
        ROW_NUMBER() OVER (
            PARTITION BY cp.cp_catalog_number
            ORDER BY cr.cr_net_loss DESC
        ) AS rn
    FROM catalog_page cp
    LEFT JOIN sampled_cr cr
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN reason r
        ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_returns sr
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE
        cp.cp_type = 'monthly'                                         -- predicate 1
        AND cr.cr_return_amount > 500.00                                 -- predicate 2
        AND cr.cr_return_quantity >= 2                                   -- predicate 3
        AND sr.sr_return_quantity BETWEEN 10 AND 80                      -- predicate 4
        AND sr.sr_net_loss < 500.00                                      -- predicate 5
        AND r.r_reason_desc LIKE '%damaged%'
)
SELECT
    cp_catalog_number,
    cp_type,
    r_reason_desc,
    cr_return_amount,
    cr_return_amt_inc_tax,
    cr_net_loss,
    sr_return_quantity,
    sr_net_loss,
    return_category,
    avg_store_net_loss,
    rn
FROM joined_data
WHERE rn <= 3   -- top‑3 rows per catalog number based on net loss
ORDER BY cp_catalog_number, rn
LIMIT 100
