WITH store_reason AS (
    SELECT r.r_reason_sk,
           r.r_reason_desc,
           sr.sr_return_amt_inc_tax,
           sr.sr_net_loss
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_return_amt_inc_tax > 100
),
web_reason AS (
    SELECT r.r_reason_sk,
           r.r_reason_desc,
           wr.wr_return_amt_inc_tax,
           wr.wr_net_loss
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_amt_inc_tax > 100
),
full_combined AS (
    SELECT COALESCE(s.r_reason_sk, w.r_reason_sk) AS reason_sk,
           COALESCE(s.r_reason_desc, w.r_reason_desc) AS reason_desc,
           s.sr_return_amt_inc_tax,
           w.wr_return_amt_inc_tax,
           s.sr_net_loss,
           w.wr_net_loss
    FROM store_reason s
    FULL OUTER JOIN web_reason w
        ON s.r_reason_sk = w.r_reason_sk
)
SELECT reason_sk,
       reason_desc,
       SUM(COALESCE(sr_return_amt_inc_tax, 0)) AS total_store_return_inc_tax,
       SUM(COALESCE(wr_return_amt_inc_tax, 0)) AS total_web_return_inc_tax,
       SUM(COALESCE(sr_net_loss, 0)) AS total_store_net_loss,
       SUM(COALESCE(wr_net_loss, 0)) AS total_web_net_loss
FROM full_combined
GROUP BY reason_sk, reason_desc
UNION ALL
SELECT -1 AS reason_sk,
       'Other' AS reason_desc,
       SUM(s.sr_return_amt_inc_tax) AS total_store_return_inc_tax,
       SUM(w.wr_return_amt_inc_tax) AS total_web_return_inc_tax,
       SUM(s.sr_net_loss) AS total_store_net_loss,
       SUM(w.wr_net_loss) AS total_web_net_loss
FROM store_reason s
FULL OUTER JOIN web_reason w
    ON s.r_reason_sk = w.r_reason_sk
WHERE s.r_reason_sk IS NULL OR w.r_reason_sk IS NULL
ORDER BY total_store_return_inc_tax DESC
LIMIT 100
