WITH sr_agg AS (
    SELECT
        sr_reason_sk,
        SUM(sr_return_amt) AS total_sr_return_amt,
        SUM(sr_fee) AS total_sr_fee,
        COUNT(*) AS sr_cnt,
        AVG(sr_store_credit) AS avg_sr_store_credit
    FROM store_returns
    WHERE sr_return_amt > 0
        AND sr_fee > 5
        AND sr_store_credit > 10
        AND sr_return_tax BETWEEN 1 AND 30
    GROUP BY sr_reason_sk
),
wr_agg AS (
    SELECT
        wr_reason_sk,
        SUM(wr_return_amt) AS total_wr_return_amt,
        SUM(wr_fee) AS total_wr_fee,
        COUNT(*) AS wr_cnt,
        AVG(wr_return_ship_cost) AS avg_wr_ship_cost
    FROM web_returns
    WHERE wr_return_amt > 0
        AND wr_fee > 5
        AND wr_return_ship_cost > 0
        AND wr_net_loss > 50
    GROUP BY wr_reason_sk
)
SELECT
    r.r_reason_id,
    r.r_reason_desc,
    sr.total_sr_return_amt,
    wr.total_wr_return_amt,
    CASE WHEN sr.total_sr_return_amt > wr.total_wr_return_amt THEN 'Store Higher' ELSE 'Web Higher' END AS higher_source,
    (sr.total_sr_return_amt + wr.total_wr_return_amt) AS combined_return_amt,
    (SELECT AVG(sr_fee) FROM store_returns sr2 WHERE sr2.sr_reason_sk = r.r_reason_sk) AS overall_avg_sr_fee,
    RANK() OVER (ORDER BY (sr.total_sr_return_amt + wr.total_wr_return_amt) DESC) AS amt_rank,
    DENSE_RANK() OVER (
        PARTITION BY CASE WHEN r.r_reason_desc LIKE '%job%' THEN 'Job' ELSE 'Other' END
        ORDER BY sr.total_sr_return_amt DESC
    ) AS sr_dense_rank,
    ROW_NUMBER() OVER (ORDER BY sr.total_sr_fee DESC) AS fee_row_num
FROM reason r
JOIN sr_agg sr ON sr.sr_reason_sk = r.r_reason_sk
JOIN wr_agg wr ON wr.wr_reason_sk = r.r_reason_sk
WHERE r.r_reason_id IN ('AAAAAAAAABAAAAAA', 'AAAAAAAAIAAAAAAA')
    AND r.r_reason_desc LIKE '%did not%'
ORDER BY combined_return_amt DESC
LIMIT 100
