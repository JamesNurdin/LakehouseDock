WITH sampled_returns AS (
    SELECT *
    FROM catalog_returns
    TABLESAMPLE BERNOULLI (5)
),
joined AS (
    SELECT
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_store_credit,
        CASE WHEN cr.cr_return_tax > 20 THEN 'HIGH_TAX' ELSE 'LOW_TAX' END AS tax_category,
        t.t_shift,
        (
            SELECT SUM(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_returned_time_sk = cr.cr_returned_time_sk
        ) AS total_amount_same_time
    FROM sampled_returns cr
    FULL OUTER JOIN time_dim t
        ON cr.cr_returned_time_sk = t.t_time_sk
)
SELECT *
FROM (
    SELECT tax_category, t_shift, cnt, sum_return_amount
    FROM (
        SELECT
            tax_category,
            t_shift,
            COUNT(*) AS cnt,
            SUM(cr_return_amount) AS sum_return_amount
        FROM joined
        WHERE cr_return_amount BETWEEN 50 AND 200
        GROUP BY tax_category, t_shift
        HAVING COUNT(*) >= 2
    )
    EXCEPT
    SELECT tax_category, t_shift, cnt, sum_return_amount
    FROM (
        SELECT
            tax_category,
            t_shift,
            COUNT(*) AS cnt,
            SUM(cr_return_amount) AS sum_return_amount
        FROM joined
        WHERE cr_return_amount > 200
        GROUP BY tax_category, t_shift
    )
) AS final_set
ORDER BY cnt DESC, sum_return_amount DESC
LIMIT 100
