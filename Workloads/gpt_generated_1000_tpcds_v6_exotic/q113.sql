WITH agg AS (
    SELECT
        cd.cd_gender AS gender,
        cd.cd_education_status AS education_status,
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_cnt
    FROM tpcds.store_returns sr
    JOIN tpcds.customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_store_credit > 100
      AND cd.cd_purchase_estimate BETWEEN 3000 AND 10000
      AND cd.cd_dep_college_count >= 1
      AND r.r_reason_id LIKE 'AAAAAAA%'
    GROUP BY ROLLUP (cd.cd_gender, cd.cd_education_status, r.r_reason_desc)
)
SELECT
    gender,
    education_status,
    reason_desc,
    total_return_amt,
    total_refunded_cash,
    return_cnt,
    SUM(total_return_amt) OVER (PARTITION BY gender) AS gender_return_sum,
    RANK() OVER (ORDER BY total_return_amt DESC) AS amt_rank,
    (SELECT AVG(total_return_amt) FROM agg) AS overall_avg_return_amt
FROM agg
WHERE total_return_amt > (SELECT AVG(total_return_amt) FROM agg)
   OR return_cnt > 50
ORDER BY total_return_amt DESC
LIMIT 100
