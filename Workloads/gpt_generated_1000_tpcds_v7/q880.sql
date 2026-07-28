WITH filtered_returns AS (
    SELECT
        wr.wr_reason_sk,
        wr.wr_return_amt,
        wr.wr_return_ship_cost,
        wr.wr_net_loss,
        r.r_reason_id,
        r.r_reason_desc
    FROM tpcds.web_returns wr
    JOIN tpcds.reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE regexp_like(r.r_reason_desc, '^Did not like')
      AND r.r_reason_id LIKE 'AAAA%AA'
)
SELECT
    r_reason_id,
    concat('Reason ', r_reason_id) AS reason_label,
    regexp_extract(r_reason_desc, '(\\w+)') AS first_word,
    substring(r_reason_desc FROM 1 FOR 15) AS short_desc,
    COUNT(*) AS total_returns,
    SUM(wr_return_amt) AS total_return_amount,
    AVG(wr_return_ship_cost) AS avg_ship_cost,
    SUM(wr_net_loss) AS total_net_loss
FROM filtered_returns
GROUP BY r_reason_id, r_reason_desc
ORDER BY total_net_loss DESC
LIMIT 10
