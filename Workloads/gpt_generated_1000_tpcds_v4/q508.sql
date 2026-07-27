WITH catalog_agg AS (
    SELECT
        w.w_state AS region,
        SUM(cr.cr_return_amount) AS total_return_amount,
        (
            SELECT AVG(cr2.cr_return_amount)
            FROM catalog_returns cr2
            WHERE cr2.cr_warehouse_sk = w.w_warehouse_sk
        ) AS avg_return_amount,
        'catalog' AS source
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2020
    GROUP BY w.w_state, w.w_warehouse_sk
),
store_agg AS (
    SELECT
        s.s_state AS region,
        SUM(sr.sr_return_amt) AS total_return_amount,
        CAST(NULL AS DOUBLE) AS avg_return_amount,
        'store' AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE d.d_year = 2020
      AND EXISTS (
          SELECT 1
          FROM store_returns sr2
          WHERE sr2.sr_store_sk = s.s_store_sk
          GROUP BY sr2.sr_store_sk
          HAVING COUNT(*) > 10
      )
    GROUP BY s.s_state, s.s_store_sk
)
SELECT DISTINCT region,
                total_return_amount,
                avg_return_amount,
                source
FROM (
    SELECT region, total_return_amount, avg_return_amount, source FROM catalog_agg
    UNION ALL
    SELECT region, total_return_amount, avg_return_amount, source FROM store_agg
) combined
ORDER BY total_return_amount DESC
LIMIT 100
