WITH max_tax AS (
    SELECT max(ss_ext_tax) AS val FROM store_sales
)
SELECT
    sub.year,
    sub.metric,
    sub.amount,
    sub.cnt,
    (SELECT val FROM max_tax) AS max_tax_overall
FROM (
    SELECT
        d.d_year AS year,
        'sales' AS metric,
        sum(s.ss_net_paid) AS amount,
        count(*) AS cnt
    FROM store_sales s
    JOIN date_dim d ON s.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
      AND s.ss_ext_tax > 100
    GROUP BY d.d_year
    UNION ALL
    SELECT
        d.d_year AS year,
        'returns' AS metric,
        sum(r.cr_return_amount) AS amount,
        count(*) AS cnt
    FROM catalog_returns r
    JOIN date_dim d ON r.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
      AND r.cr_return_amount > 50
    GROUP BY d.d_year
) sub
ORDER BY sub.year, sub.metric
LIMIT 100
