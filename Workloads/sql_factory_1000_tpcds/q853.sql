WITH return_sales AS (
    SELECT
        wr.wr_returning_customer_sk,
        SUM(wr.wr_net_loss) AS total_return_loss,
        SUM(ws.ws_net_profit) AS total_original_profit,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_quantity) AS total_return_qty
    FROM web_returns wr
    JOIN web_sales ws
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = ws.ws_item_sk
    GROUP BY wr.wr_returning_customer_sk
),
return_hour AS (
    SELECT
        wr.wr_returning_customer_sk,
        t.t_hour,
        COUNT(*) AS hour_cnt,
        ROW_NUMBER() OVER (PARTITION BY wr.wr_returning_customer_sk ORDER BY COUNT(*) DESC) AS rn
    FROM web_returns wr
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    GROUP BY wr.wr_returning_customer_sk, t.t_hour
)
SELECT
    rs.wr_returning_customer_sk,
    rs.total_original_profit,
    rs.total_return_loss,
    rs.return_cnt,
    rs.total_return_qty,
    (rs.total_original_profit - rs.total_return_loss) AS net_effect,
    DENSE_RANK() OVER (ORDER BY rs.total_return_loss DESC) AS loss_rank,
    CASE
        WHEN rs.total_return_loss > 10000 THEN 'Critical'
        WHEN rs.total_return_loss > 5000 THEN 'High'
        WHEN rs.total_return_loss > 1000 THEN 'Medium'
        ELSE 'Low'
    END AS loss_severity,
    rh.t_hour AS peak_return_hour
FROM return_sales rs
LEFT JOIN return_hour rh
  ON rs.wr_returning_customer_sk = rh.wr_returning_customer_sk
 AND rh.rn = 1
WHERE rs.total_return_loss > 0
ORDER BY rs.total_return_loss DESC
LIMIT 5
