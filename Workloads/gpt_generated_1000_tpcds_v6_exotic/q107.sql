WITH recent_returns AS (
    SELECT
        sr_hdemo_sk,
        sr_return_amt_inc_tax,
        sr_fee,
        sr_reversed_charge
    FROM store_returns
    WHERE sr_return_amt_inc_tax >= 50
)
SELECT
    hd.hd_buy_potential,
    CONCAT('Potential range ', hd.hd_buy_potential) AS potential_desc,
    regexp_extract(hd.hd_buy_potential, '(\\d+)-', 1) AS lower_bound,
    substring(hd.hd_buy_potential FROM 1 FOR 4) AS prefix,
    COUNT(DISTINCT rr.sr_hdemo_sk) AS household_cnt,
    SUM(rr.sr_return_amt_inc_tax) AS total_inc_tax,
    AVG(rr.sr_fee) AS avg_fee
FROM recent_returns rr
JOIN household_demographics hd
    ON rr.sr_hdemo_sk = hd.hd_demo_sk
WHERE
    regexp_like(hd.hd_buy_potential, '^([5-9][0-9]{3,4})-')
    AND hd.hd_buy_potential LIKE '%-10000'
    AND EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_hdemo_sk = hd.hd_demo_sk
          AND sr3.sr_reversed_charge > 30
    )
GROUP BY
    hd.hd_buy_potential,
    CONCAT('Potential range ', hd.hd_buy_potential),
    regexp_extract(hd.hd_buy_potential, '(\\d+)-', 1),
    substring(hd.hd_buy_potential FROM 1 FOR 4)
ORDER BY total_inc_tax DESC
LIMIT 100
