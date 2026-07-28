WITH catalog_ret AS (
    SELECT d.d_date AS return_date,
           r.r_reason_desc,
           cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_return_quantity > 0
      AND cr.cr_reason_sk IN (
          SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%price%'
      )
),
web_ret AS (
    SELECT d.d_date AS return_date,
           r.r_reason_desc,
           wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    WHERE wr.wr_return_quantity > 0
      AND wr.wr_reason_sk IN (
          SELECT r_reason_sk FROM reason WHERE r_reason_desc LIKE '%price%'
      )
)
SELECT
    date_trunc('month', combined.return_date) AS month,
    combined.r_reason_desc AS reason_desc,
    SUM(combined.net_loss) AS total_net_loss,
    COUNT(*) AS cnt_returns,
    (SELECT AVG(p_cost) FROM promotion WHERE p_channel_catalog = 'N') AS avg_catalog_promo_cost
FROM (
    SELECT return_date, r_reason_desc, net_loss FROM catalog_ret
    UNION ALL
    SELECT return_date, r_reason_desc, net_loss FROM web_ret
) AS combined
GROUP BY date_trunc('month', combined.return_date), combined.r_reason_desc
ORDER BY month, total_net_loss DESC
