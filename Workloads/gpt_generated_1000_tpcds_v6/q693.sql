WITH filtered_date AS (
    SELECT *
    FROM date_dim
    WHERE d_year = 2001
      AND d_month_seq BETWEEN 1200 AND 1211
      AND d_day_name = 'Monday'
      AND d_date BETWEEN DATE '2001-01-01' AND DATE '2001-12-31'
)
SELECT
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    i.inv_warehouse_sk,
    COUNT(DISTINCT ws.ws_order_number) AS orders_count,
    SUM(ws.ws_net_paid_inc_tax) AS total_net_paid_inc_tax,
    AVG(ws.ws_wholesale_cost) AS avg_wholesale_cost,
    SUM(COALESCE(sr.sr_net_loss, 0)) AS total_return_loss,
    MIN(ws.ws_net_profit) AS min_net_profit,
    MAX(ws.ws_net_profit) AS max_net_profit
FROM filtered_date d
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON t.t_time_sk = ws.ws_sold_time_sk
JOIN inventory i
    ON i.inv_date_sk = d.d_date_sk
LEFT JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_return_time_sk = t.t_time_sk
WHERE i.inv_warehouse_sk IN (7, 14, 20)
  AND ws.ws_net_paid_inc_tax > 1000
  AND ws.ws_quantity >= 2
  AND t.t_hour BETWEEN 9 AND 17
  AND i.inv_quantity_on_hand > 0
  AND (sr.sr_return_quantity IS NULL OR sr.sr_return_quantity = 1)
GROUP BY d.d_year, d.d_month_seq, t.t_hour, i.inv_warehouse_sk
ORDER BY total_net_paid_inc_tax DESC
LIMIT 100
