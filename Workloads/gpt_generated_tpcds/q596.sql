WITH
  store_agg AS (
    SELECT
      sr_reason_sk,
      SUM(sr_return_quantity) AS store_return_qty,
      SUM(sr_return_amt) AS store_return_amt,
      SUM(sr_net_loss) AS store_net_loss
    FROM store_returns
    GROUP BY sr_reason_sk
  ),
  web_agg AS (
    SELECT
      wr_reason_sk,
      SUM(wr_return_quantity) AS web_return_qty,
      SUM(wr_return_amt) AS web_return_amt,
      SUM(wr_net_loss) AS web_net_loss
    FROM web_returns
    GROUP BY wr_reason_sk
  )
SELECT
  r.r_reason_desc,
  COALESCE(store_agg.store_return_qty, 0) AS total_store_return_qty,
  COALESCE(web_agg.web_return_qty, 0) AS total_web_return_qty,
  COALESCE(store_agg.store_return_amt, 0) AS total_store_return_amt,
  COALESCE(web_agg.web_return_amt, 0) AS total_web_return_amt,
  COALESCE(store_agg.store_net_loss, 0) AS total_store_net_loss,
  COALESCE(web_agg.web_net_loss, 0) AS total_web_net_loss,
  COALESCE(store_agg.store_return_qty, 0) + COALESCE(web_agg.web_return_qty, 0) AS total_return_qty,
  COALESCE(store_agg.store_return_amt, 0) + COALESCE(web_agg.web_return_amt, 0) AS total_return_amt,
  COALESCE(store_agg.store_net_loss, 0) + COALESCE(web_agg.web_net_loss, 0) AS total_net_loss
FROM reason r
LEFT JOIN store_agg ON store_agg.sr_reason_sk = r.r_reason_sk
LEFT JOIN web_agg ON web_agg.wr_reason_sk = r.r_reason_sk
ORDER BY total_net_loss DESC
LIMIT 20
