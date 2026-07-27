WITH high_ship_cost AS (
    SELECT
        wr_reason_sk,
        wr_return_amt,
        wr_net_loss,
        wr_return_quantity,
        wr_return_ship_cost
    FROM web_returns
    WHERE wr_return_ship_cost > 100
)
SELECT
    r.r_reason_desc,
    REGEXP_EXTRACT(r.r_reason_desc, '(\\w+)') AS first_word,
    SUBSTRING(r.r_reason_desc FROM 1 FOR 10) AS short_desc,
    COUNT(*) AS num_returns,
    SUM(h.wr_net_loss) AS total_net_loss,
    AVG(h.wr_return_amt) AS avg_return_amt,
    (SELECT AVG(wr_net_loss) FROM web_returns) AS overall_avg_net_loss,
    (AVG(h.wr_net_loss) > (SELECT AVG(wr_net_loss) FROM web_returns)) AS above_avg
FROM high_ship_cost h
JOIN reason r
    ON h.wr_reason_sk = r.r_reason_sk
WHERE REGEXP_LIKE(r.r_reason_desc, '(?i)gift')
  AND r.r_reason_id LIKE '%A'
GROUP BY
    r.r_reason_desc,
    REGEXP_EXTRACT(r.r_reason_desc, '(\\w+)'),
    SUBSTRING(r.r_reason_desc FROM 1 FOR 10)
HAVING COUNT(*) > 5
ORDER BY total_net_loss DESC
LIMIT 100
