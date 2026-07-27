WITH store_return_summary AS (
    SELECT
        s.s_store_sk AS store_sk,
        s.s_store_id,
        s.s_state,
        s.s_zip,
        s.s_number_employees,
        s.s_market_id,
        SUM(sr.sr_return_amt) AS total_return_amt,
        SUM(sr.sr_fee) AS total_fee,
        COUNT(*) AS return_cnt,
        AVG(sr.sr_return_amt) AS avg_return_amt
    FROM store_returns sr
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE sr.sr_return_amt > 100
      AND sr.sr_fee BETWEEN 20 AND 80
      AND s.s_state = 'CA'
      AND s.s_zip LIKE '3%'
      AND s.s_number_employees >= 50
      AND s.s_market_id IN (1, 2, 3)
    GROUP BY s.s_store_sk, s.s_store_id, s.s_state, s.s_zip, s.s_number_employees, s.s_market_id
)
SELECT
    srs.s_store_id,
    srs.s_state,
    srs.s_zip,
    srs.total_return_amt,
    srs.total_fee,
    srs.return_cnt,
    srs.avg_return_amt,
    ROW_NUMBER() OVER (ORDER BY srs.total_return_amt DESC) AS rn,
    AVG(srs.total_return_amt) OVER () AS overall_avg_return_amt
FROM store_return_summary srs
WHERE EXISTS (
        SELECT 1
        FROM store s2
        WHERE s2.s_store_sk = srs.store_sk
          AND s2.s_gmt_offset > -5
    )
  AND srs.total_return_amt > (
        SELECT AVG(total_return_amt) FROM store_return_summary
    )
ORDER BY srs.total_return_amt DESC
LIMIT 100
