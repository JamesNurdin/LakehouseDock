WITH filtered_returns AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_returning_hdemo_sk,
        hd.hd_buy_potential,
        CAST(regexp_extract(hd.hd_buy_potential, '(\\d+)-', 1) AS integer) AS lower_bound,
        CAST(regexp_extract(hd.hd_buy_potential, '-(\\d+)', 1) AS integer) AS upper_bound
    FROM catalog_returns cr
    JOIN household_demographics hd
        ON cr.cr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE regexp_like(hd.hd_buy_potential, '^\\d+-\\d+$')
      AND hd.hd_buy_potential LIKE '%-%'
      AND cr.cr_return_amount > 0
)
SELECT
    fr.hd_buy_potential,
    CONCAT('Range ', fr.hd_buy_potential) AS range_label,
    fr.lower_bound,
    COUNT(DISTINCT fr.cr_return_quantity) AS distinct_quantity_cnt,
    SUM(fr.cr_return_amount) AS total_return_amount,
    AVG(fr.cr_return_amount) AS avg_return_amount
FROM filtered_returns fr
GROUP BY fr.hd_buy_potential, fr.lower_bound
HAVING AVG(fr.cr_return_amount) > (SELECT AVG(cr_return_amount) FROM catalog_returns)
ORDER BY fr.lower_bound ASC
LIMIT 100
