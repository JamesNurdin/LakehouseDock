WITH base AS (
  SELECT
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_net_profit,
    ss.ss_ticket_number,
    ss.ss_coupon_amt,
    ss.ss_net_paid,
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_warehouse_sk,
    ws.ws_net_paid,
    ws.ws_ext_sales_price,
    wr.wr_return_amt,
    d1.d_year,
    w.w_state,
    w.w_warehouse_name,
    web.web_name,
    web.web_class
  FROM catalog_sales cs
  JOIN date_dim d1 ON cs.cs_sold_date_sk = d1.d_date_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN store_sales ss ON ss.ss_sold_date_sk = d1.d_date_sk
  JOIN web_sales ws ON ws.ws_sold_date_sk = d1.d_date_sk
                     AND ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
   AND ws.ws_sold_date_sk = wr.wr_returned_date_sk
  WHERE d1.d_year = 2001
    AND w.w_state IN ('CA', 'NY')
    AND cs.cs_quantity > 1
    AND ws.ws_net_paid > 500
    AND ss.ss_coupon_amt < 2000
    AND web.web_class = 'A'
),
returns_only AS (
  SELECT cs_order_number FROM base WHERE wr_return_amt IS NOT NULL
  EXCEPT
  SELECT cs_order_number FROM base WHERE wr_return_amt IS NULL
),
filtered AS (
  SELECT b.* FROM base b
  JOIN returns_only ro ON b.cs_order_number = ro.cs_order_number
)
SELECT
  d_year,
  w_state,
  web_name,
  SUM(cs_net_profit) + SUM(ss_net_paid) + SUM(ws_net_paid) - COALESCE(SUM(wr_return_amt), 0) AS total_profit,
  COUNT(DISTINCT cs_order_number) AS distinct_orders,
  RANK() OVER (ORDER BY SUM(cs_net_profit) + SUM(ss_net_paid) + SUM(ws_net_paid) - COALESCE(SUM(wr_return_amt), 0) DESC) AS profit_rank,
  daily_total.ws_daily_total
FROM filtered
LEFT JOIN LATERAL (
   SELECT SUM(ws2.ws_ext_sales_price) AS ws_daily_total
   FROM web_sales ws2
   WHERE ws2.ws_sold_date_sk = filtered.ws_sold_date_sk
     AND ws2.ws_warehouse_sk = filtered.ws_warehouse_sk
) AS daily_total ON TRUE
GROUP BY CUBE (d_year, w_state, web_name), daily_total.ws_daily_total
HAVING COUNT(*) > 5
ORDER BY total_profit DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
