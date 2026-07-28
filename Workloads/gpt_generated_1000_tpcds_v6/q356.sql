WITH joined AS (
  SELECT
    sr.sr_net_loss,
    wr.wr_net_loss,
    ws.ws_net_profit,
    c.c_customer_sk,
    s.s_store_name AS s_store_name,
    s.s_state AS s_state,
    cc.cc_division_name AS cc_division_name,
    d.d_year AS d_year
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN store s ON sr.sr_store_sk = s.s_store_sk
  JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
  JOIN inventory i ON i.inv_date_sk = d.d_date_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
                     AND ws.ws_sold_time_sk = t.t_time_sk
                     AND ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                       AND wr.wr_returned_time_sk = t.t_time_sk
                       AND wr.wr_item_sk = ws.ws_item_sk
                       AND wr.wr_order_number = ws.ws_order_number
                       AND wr.wr_refunded_customer_sk = c.c_customer_sk
  WHERE d.d_year = 2001
    AND t.t_hour = 13
    AND s.s_state = 'CA'
    AND cc.cc_division_name = 'able'
    AND i.inv_quantity_on_hand > 0
),
aggregated AS (
  SELECT
    s_store_name,
    d_year,
    cc_division_name,
    s_state,
    SUM(sr_net_loss) AS total_store_return_loss,
    SUM(wr_net_loss) AS total_web_return_loss,
    SUM(ws_net_profit) AS total_sales_profit,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    CASE WHEN SUM(ws_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_category
  FROM joined
  GROUP BY s_store_name, d_year, cc_division_name, s_state
)
SELECT
  *,
  RANK() OVER (ORDER BY total_store_return_loss DESC) AS loss_rank,
  SUM(total_store_return_loss) OVER (PARTITION BY cc_division_name) AS division_total_return_loss
FROM aggregated
ORDER BY total_store_return_loss DESC
LIMIT 100
