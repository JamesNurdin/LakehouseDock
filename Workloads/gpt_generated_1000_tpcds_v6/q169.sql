WITH
  store_part AS (
    SELECT
      r.r_reason_desc AS reason_desc,
      t.t_hour        AS hour,
      sr.sr_store_sk  AS store_sk,
      sr.sr_net_loss  AS net_loss,
      'store'         AS src,
      t.t_time_sk     AS time_sk
    FROM store_returns sr
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE sr.sr_store_credit > 10
      AND sr.sr_return_ship_cost < 500
      AND sr.sr_return_quantity >= 1
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND r.r_reason_sk IN (SELECT r_reason_sk FROM reason WHERE r_reason_id LIKE 'AAAAAAA%')
      AND sr.sr_store_sk BETWEEN 700 AND 1000
  ),
  web_part AS (
    SELECT
      r.r_reason_desc      AS reason_desc,
      t.t_hour             AS hour,
      ws.ws_bill_hdemo_sk  AS demo_sk,
      wr.wr_net_loss       AS net_loss,
      'web'                AS src,
      t.t_time_sk          AS time_sk
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk
                     AND wr.wr_order_number = ws.ws_order_number
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    WHERE ws.ws_quantity > 2
      AND ws.ws_wholesale_cost > 5
      AND wr.wr_return_quantity >= 1
      AND wr.wr_return_amt_inc_tax < 1000
      AND r.r_reason_id LIKE 'AAAAAAA%'
      AND ws.ws_ship_hdemo_sk NOT IN (SELECT ws_ship_hdemo_sk FROM web_sales WHERE ws_ship_hdemo_sk IS NULL)
  ),
  combined AS (
    SELECT * FROM store_part
    UNION ALL
    SELECT * FROM web_part
  ),
  agg AS (
    SELECT
      reason_desc,
      hour,
      SUM(net_loss)                                            AS total_net_loss,
      COUNT(*)                                                 AS cnt,
      SUM(CASE WHEN src = 'store' THEN net_loss ELSE 0 END)   AS store_loss,
      SUM(CASE WHEN src = 'web'   THEN net_loss ELSE 0 END)   AS web_loss
    FROM combined
    GROUP BY GROUPING SETS (
        (reason_desc, hour),
        (reason_desc),
        ()
    )
  )
SELECT
  reason_desc,
  hour,
  total_net_loss,
  store_loss,
  web_loss,
  cnt,
  RANK() OVER (PARTITION BY reason_desc ORDER BY total_net_loss DESC) AS loss_rank,
  SUM(total_net_loss) OVER (ORDER BY total_net_loss DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_loss,
  CASE
    WHEN total_net_loss > (SELECT AVG(sr_net_loss) FROM store_returns) THEN 'HIGH'
    ELSE 'LOW'
  END AS loss_level
FROM agg
WHERE total_net_loss IS NOT NULL
ORDER BY total_net_loss DESC
LIMIT 100
