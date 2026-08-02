WITH sr_sample AS (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
)
SELECT
    hd.hd_buy_potential,
    r.r_reason_desc,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity
FROM sr_sample sr
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE hd.hd_buy_potential = '5001-10000'
  AND r.r_reason_desc LIKE '%size%'
GROUP BY hd.hd_buy_potential, r.r_reason_desc

UNION ALL

SELECT
    hd.hd_buy_potential,
    r.r_reason_desc,
    SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
    SUM(sr.sr_return_quantity) AS total_return_quantity
FROM (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
) sr
JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
WHERE hd.hd_buy_potential = '0-500'
  AND r.r_reason_desc LIKE '%time%'
GROUP BY hd.hd_buy_potential, r.r_reason_desc

ORDER BY total_return_amount DESC
LIMIT 100
