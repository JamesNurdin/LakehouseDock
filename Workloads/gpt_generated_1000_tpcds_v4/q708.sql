WITH sub1 AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        COUNT(*) AS cnt_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_fee) AS avg_fee,
        MIN(sr.sr_return_amt_inc_tax) AS min_return_inc_tax,
        MAX(sr.sr_return_amt_inc_tax) AS max_return_inc_tax
    FROM tpcds.reason r
    JOIN tpcds.store_returns sr
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id = 'AAAAAAAAGAAAAAAA'
      AND sr.sr_fee > 50
      AND sr.sr_return_ship_cost BETWEEN 100 AND 500
      AND sr.sr_return_quantity > 1
      AND sr.sr_reversed_charge > 20
    GROUP BY r.r_reason_desc
),
sub2 AS (
    SELECT
        r.r_reason_desc AS reason_desc,
        COUNT(*) AS cnt_returns,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_fee) AS avg_fee,
        MIN(sr.sr_return_amt_inc_tax) AS min_return_inc_tax,
        MAX(sr.sr_return_amt_inc_tax) AS max_return_inc_tax
    FROM tpcds.reason r
    JOIN tpcds.store_returns sr
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_id = 'AAAAAAAADAAAAAAA'
      AND sr.sr_fee < 80
      AND sr.sr_return_ship_cost BETWEEN 200 AND 600
      AND sr.sr_return_quantity <= 3
      AND sr.sr_reversed_charge BETWEEN 10 AND 100
    GROUP BY r.r_reason_desc
)
SELECT
    reason_desc,
    SUM(cnt_returns) AS total_returns,
    SUM(total_return_amt) AS sum_return_amt,
    AVG(avg_fee) AS avg_fee_overall,
    MIN(min_return_inc_tax) AS overall_min_inc_tax,
    MAX(max_return_inc_tax) AS overall_max_inc_tax
FROM (
    SELECT * FROM sub1
    UNION ALL
    SELECT * FROM sub2
) AS combined
GROUP BY reason_desc
ORDER BY total_returns DESC
LIMIT 100
