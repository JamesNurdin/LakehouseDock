WITH agg_returns AS (
    SELECT
        sr_store_sk,
        sr_returned_date_sk,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS return_cnt
    FROM store_returns
    WHERE sr_fee > 20
      AND sr_return_amt_inc_tax > 0
      AND sr_hdemo_sk IN (
          SELECT v.hdemo_sk
          FROM (VALUES (2455), (7157), (1497), (2351), (1877)) AS v(hdemo_sk)
      )
    GROUP BY sr_store_sk, sr_returned_date_sk
)
SELECT
    d.d_year,
    d.d_month_seq,
    ws.web_state,
    agg.total_net_loss,
    agg.return_cnt,
    CASE WHEN agg.total_net_loss > 1000 THEN 'HIGH' ELSE 'LOW' END AS loss_category,
    (SELECT MAX(sr_fee) FROM store_returns) AS max_fee_overall
FROM agg_returns agg
JOIN date_dim d
    ON agg.sr_returned_date_sk = d.d_date_sk
JOIN web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_month_seq BETWEEN 1 AND 12
  AND d.d_dow IN (1, 2, 3)
  AND ws.web_state = 'CA'
  AND ws.web_gmt_offset BETWEEN -8 AND -5
GROUP BY d.d_year, d.d_month_seq, ws.web_state, agg.total_net_loss, agg.return_cnt
HAVING agg.return_cnt > 5
ORDER BY d.d_year DESC, loss_category ASC
LIMIT 100
