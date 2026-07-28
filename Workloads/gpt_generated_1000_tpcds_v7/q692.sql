WITH filtered AS (
    SELECT
        sr.sr_return_amt_inc_tax,
        sr.sr_refunded_cash,
        sr.sr_return_quantity,
        s.s_state,
        s.s_county,
        cd.cd_gender,
        cd.cd_dep_count
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    WHERE s.s_county IN ('Pennington County', 'Richland County')
      AND s.s_tax_percentage BETWEEN 0.02 AND 0.05
      AND cd.cd_gender = 'F'
      AND cd.cd_dep_count >= 2
      AND sr.sr_return_amt_inc_tax > 100
)
SELECT
    s_state,
    s_county,
    cd_gender,
    SUM(sr_return_amt_inc_tax) AS total_return_amt_inc_tax,
    AVG(sr_refunded_cash) AS avg_refunded_cash,
    COUNT(*) AS return_count,
    MIN(sr_return_quantity) AS min_return_qty,
    MAX(sr_return_quantity) AS max_return_qty
FROM filtered
GROUP BY ROLLUP (s_state, s_county, cd_gender)
ORDER BY total_return_amt_inc_tax DESC
LIMIT 100
