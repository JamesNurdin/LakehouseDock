WITH sales_agg AS (
  SELECT
    d.d_date,
    cs.cs_warehouse_sk,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns,
    AVG(ws.ws_net_paid_inc_ship_tax) AS avg_web_paid,
    SUM(CASE WHEN cs.cs_ext_discount_amt > 500 THEN cs.cs_ext_discount_amt ELSE 0 END) AS total_big_discount
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  JOIN catalog_sales cs ON cs.cs_sold_time_sk = t.t_time_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2002
    AND d.d_month_seq BETWEEN 1200 AND 1300
    AND t.t_hour BETWEEN 8 AND 17
    AND cs.cs_warehouse_sk IN (5, 7, 10)
    AND cs.cs_ext_sales_price > 1000
    AND sr.sr_net_loss < 0
    AND ws.ws_net_paid_inc_ship_tax > 500
  GROUP BY d.d_date, cs.cs_warehouse_sk
)
SELECT
  sa.d_date,
  sa.cs_warehouse_sk,
  sa.total_net_profit,
  sa.distinct_returns,
  sa.avg_web_paid,
  CASE
    WHEN sa.total_net_profit > 10000 THEN 'HIGH'
    WHEN sa.total_net_profit > 0 THEN 'POSITIVE'
    ELSE 'NEGATIVE'
  END AS profit_category
FROM sales_agg sa
WHERE sa.total_big_discount > (
    SELECT AVG(total_big_discount) * 1.2 FROM sales_agg
  )
ORDER BY sa.total_net_profit DESC
LIMIT 100
