WITH sales_returns AS (
  SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    d_sold.d_date AS sold_date,
    ws.ws_warehouse_sk,
    w.w_warehouse_name,
    ws.ws_item_sk,
    i.i_product_name,
    ws.ws_net_profit,
    ws.ws_quantity,
    ws.ws_sales_price,
    ws.ws_ext_sales_price,
    ws.ws_ext_discount_amt,
    ws.ws_ext_tax,
    ws.ws_sold_time_sk,
    t.t_hour,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    r.r_reason_desc,
    cd.cd_gender,
    ca.ca_state
  FROM web_sales ws
  JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t
    ON ws.ws_sold_time_sk = t.t_time_sk
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
  JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  FULL OUTER JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
  LEFT JOIN reason r
    ON wr.wr_reason_sk = r.r_reason_sk
  LEFT JOIN customer_demographics cd_ret
    ON wr.wr_refunded_cdemo_sk = cd_ret.cd_demo_sk
  LEFT JOIN customer_address ca_ret
    ON wr.wr_refunded_addr_sk = ca_ret.ca_address_sk
  WHERE d_sold.d_year = 2001
    AND w.w_warehouse_sq_ft > 500000
    AND i.i_current_price > 100
    AND r.r_reason_desc NOT LIKE '%damaged%'
    AND t.t_hour BETWEEN 9 AND 17
    AND cd.cd_gender = 'M'
),
agg AS (
  SELECT
    sr.ws_warehouse_sk,
    w.w_warehouse_name,
    sr.r_reason_desc,
    SUM(sr.ws_ext_sales_price) AS total_sales,
    SUM(sr.ws_net_profit) AS total_profit,
    COUNT(DISTINCT sr.ws_order_number) AS orders,
    AVG(sr.ws_quantity) AS avg_qty
  FROM sales_returns sr
  JOIN warehouse w
    ON sr.ws_warehouse_sk = w.w_warehouse_sk
  WHERE EXISTS (
    SELECT 1
    FROM inventory inv
    WHERE inv.inv_item_sk = sr.ws_item_sk
      AND inv.inv_date_sk = sr.ws_sold_date_sk
      AND inv.inv_quantity_on_hand > 0
  )
  GROUP BY sr.ws_warehouse_sk, w.w_warehouse_name, sr.r_reason_desc
)
SELECT
  a.ws_warehouse_sk,
  a.w_warehouse_name,
  a.r_reason_desc,
  a.total_sales,
  a.total_profit,
  a.orders,
  a.avg_qty,
  LAG(a.total_profit) OVER (PARTITION BY a.ws_warehouse_sk ORDER BY a.total_sales DESC) AS prev_warehouse_profit
FROM agg a
WHERE a.total_sales > 10000
ORDER BY a.total_profit DESC
LIMIT 100
