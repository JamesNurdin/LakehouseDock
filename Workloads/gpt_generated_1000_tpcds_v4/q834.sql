WITH store_loss AS (
    SELECT
        d.d_month_seq AS month_seq,
        r.r_reason_desc AS reason_desc,
        SUM(sr.sr_net_loss) AS loss,
        'store' AS source
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
    GROUP BY d.d_month_seq, r.r_reason_desc
),
web_loss AS (
    SELECT
        d.d_month_seq AS month_seq,
        r.r_reason_desc AS reason_desc,
        SUM(wr.wr_net_loss) AS loss,
        'web' AS source
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_category = 'Sports'
    GROUP BY d.d_month_seq, r.r_reason_desc
),
combined AS (
    SELECT * FROM store_loss
    UNION ALL
    SELECT * FROM web_loss
)
SELECT
    c.month_seq,
    c.reason_desc,
    c.source,
    c.loss,
    CASE WHEN c.loss > 1000 THEN 'High' ELSE 'Low' END AS loss_level,
    (SELECT AVG(loss) FROM combined) AS avg_monthly_loss
FROM combined c
WHERE c.reason_desc IN (
    SELECT r_reason_desc FROM reason WHERE r_reason_desc LIKE '%defect%'
)
ORDER BY c.month_seq, c.loss DESC
LIMIT 100
