WITH reason_agg AS (
    SELECT
        r.r_reason_sk,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '(\\w+)\\s+\\w+$', 1) AS last_word,
        SUM(w.wr_return_amt) AS total_return_amt,
        SUM(w.wr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM tpcds.reason r
    JOIN tpcds.web_returns w
        ON w.wr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc LIKE '%product%'
      AND regexp_like(r.r_reason_desc, 'size|warranty')
    GROUP BY
        r.r_reason_sk,
        r.r_reason_desc,
        regexp_extract(r.r_reason_desc, '(\\w+)\\s+\\w+$', 1)
)
SELECT
    ra.r_reason_desc,
    ra.last_word,
    ra.total_return_amt,
    ra.total_net_loss,
    ra.return_cnt,
    CONCAT(ra.r_reason_desc, ' (', ra.last_word, ')') AS desc_with_last,
    (
        SELECT AVG(w2.wr_return_amt)
        FROM tpcds.web_returns w2
        WHERE w2.wr_reason_sk = ra.r_reason_sk
    ) AS avg_return_amt,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM tpcds.web_returns w3
            WHERE w3.wr_reason_sk = ra.r_reason_sk
              AND w3.wr_return_ship_cost > 500
        ) THEN 'HighShipCost'
        ELSE 'NormalShipCost'
    END AS ship_cost_flag
FROM reason_agg ra
ORDER BY ra.total_net_loss DESC
LIMIT 100
