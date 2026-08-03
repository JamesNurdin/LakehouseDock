WITH return_agg AS (
   SELECT
       wr.wr_returned_date_sk,
       wr.wr_reason_sk,
       COUNT(*) AS cnt_returns,
       SUM(wr.wr_return_amt) AS total_return_amt,
       SUM(wr.wr_net_loss) AS total_return_loss
   FROM web_returns wr
   WHERE wr.wr_return_ship_cost > 100.00
     AND wr.wr_return_tax >= 20.00
     AND wr.wr_reversed_charge < 300.00
   GROUP BY wr.wr_returned_date_sk, wr.wr_reason_sk
)
SELECT
   d_ret.d_year,
   d_ret.d_month_seq,
   r.r_reason_desc,
   SUM(ss.ss_net_profit)          AS store_net_profit,
   SUM(cs.cs_net_profit)          AS catalog_net_profit,
   SUM(ws.ws_net_profit)          AS web_net_profit,
   SUM(ra.cnt_returns)            AS return_count,
   SUM(ra.total_return_amt)       AS return_amount,
   SUM(ra.total_return_loss)      AS return_loss
FROM return_agg ra
JOIN reason r
  ON ra.wr_reason_sk = r.r_reason_sk
JOIN date_dim d_ret
  ON ra.wr_returned_date_sk = d_ret.d_date_sk
JOIN web_returns wr
  ON wr.wr_returned_date_sk = d_ret.d_date_sk
 AND wr.wr_reason_sk = r.r_reason_sk
JOIN web_sales ws
  ON ws.ws_order_number = wr.wr_order_number
JOIN time_dim t_ws
  ON ws.ws_sold_time_sk = t_ws.t_time_sk
JOIN web_site we
  ON ws.ws_web_site_sk = we.web_site_sk
JOIN date_dim d_ws_open
  ON we.web_open_date_sk = d_ws_open.d_date_sk
JOIN date_dim d_ws_ship
  ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN date_dim d_ws_sold
  ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN catalog_sales cs
  ON cs.cs_sold_date_sk = d_ret.d_date_sk
JOIN time_dim t_cs
  ON cs.cs_sold_time_sk = t_cs.t_time_sk
JOIN customer_demographics cd
  ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN store_sales ss
  ON ss.ss_sold_date_sk = d_ret.d_date_sk
JOIN time_dim t_ss
  ON ss.ss_sold_time_sk = t_ss.t_time_sk
WHERE d_ret.d_fy_year = 1909
  AND t_ws.t_hour BETWEEN 9 AND 17
  AND cd.cd_gender = 'M'
  AND we.web_country = 'United States'
  AND ss.ss_quantity > 5
  AND cs.cs_quantity < 10
  AND r.r_reason_desc = 'Customer Not Satisfied'
GROUP BY ROLLUP (d_ret.d_year, d_ret.d_month_seq, r.r_reason_desc)
ORDER BY d_ret.d_year NULLS LAST, d_ret.d_month_seq NULLS LAST, r.r_reason_desc
LIMIT 100
