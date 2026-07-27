WITH aggregated AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        r.r_reason_desc,
        cd.cd_gender,
        CASE WHEN sr.sr_return_amt > (SELECT AVG(sr_return_amt) FROM store_returns) THEN 'High' ELSE 'Low' END AS amt_category,
        COUNT(*) AS returns_cnt,
        SUM(sr.sr_return_amt) AS total_return_amt,
        AVG(sr.sr_return_amt) AS avg_return_amt,
        MIN(sr.sr_return_amt) AS min_return_amt,
        MAX(sr.sr_return_amt) AS max_return_amt
    FROM store_returns sr
    INNER JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    INNER JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    INNER JOIN store s ON sr.sr_store_sk = s.s_store_sk
    INNER JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Lost my job'
      AND s.s_country = 'United States'
      AND c.c_first_shipto_date_sk = 2451346
      AND sr.sr_return_amt > 100.00
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        r.r_reason_desc,
        cd.cd_gender,
        CASE WHEN sr.sr_return_amt > (SELECT AVG(sr_return_amt) FROM store_returns) THEN 'High' ELSE 'Low' END
)
SELECT
    a.s_store_id,
    a.s_store_name,
    a.r_reason_desc,
    a.cd_gender,
    a.amt_category,
    a.returns_cnt,
    a.total_return_amt,
    a.avg_return_amt,
    a.min_return_amt,
    a.max_return_amt,
    SUM(a.total_return_amt) OVER (
        PARTITION BY a.s_store_id
        ORDER BY a.total_return_amt DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_by_store
FROM aggregated a
ORDER BY a.total_return_amt DESC
LIMIT 100
