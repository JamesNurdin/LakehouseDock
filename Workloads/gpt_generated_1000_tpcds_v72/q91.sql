WITH
sales_base AS (
  SELECT
    ws.ws_sold_date_sk,
    ws.ws_sold_time_sk,
    ws.ws_item_sk,
    ws.ws_bill_customer_sk,
    ws.ws_bill_cdemo_sk,
    ws.ws_bill_hdemo_sk,
    ws.ws_quantity,
    ws.ws_net_profit,
    i.i_item_id,
    i.i_category,
    i.i_class,
    i.i_size,
    i.i_current_price,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    t.t_hour
  FROM web_sales ws
  JOIN item i ON ws.ws_item_sk = i.i_item_sk
  JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
  WHERE ws.ws_wholesale_cost > 30
    AND ws.ws_net_profit > 0
    AND i.i_class = 'hockey'
    AND cd.cd_gender = 'M'
    AND t.t_hour BETWEEN 8 AND 17
),
returns_base AS (
  SELECT
    wr.wr_returned_date_sk,
    wr.wr_returned_time_sk,
    wr.wr_item_sk,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_net_loss,
    i.i_item_id,
    ws.ws_order_number,
    rc.c_customer_id AS customer_id,
    t.t_hour AS return_hour
  FROM web_returns wr
  JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk
                     AND wr.wr_order_number = ws.ws_order_number
  JOIN item i ON wr.wr_item_sk = i.i_item_sk
  JOIN customer rc ON wr.wr_refunded_customer_sk = rc.c_customer_sk
  JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
  WHERE wr.wr_return_amt > 20
    AND t.t_hour >= 12
),
store_ret_base AS (
  SELECT
    sr.sr_returned_date_sk,
    sr.sr_return_time_sk,
    sr.sr_item_sk,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_net_loss,
    i.i_item_id,
    t.t_hour AS store_return_hour
  FROM store_returns sr
  JOIN item i ON sr.sr_item_sk = i.i_item_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  WHERE sr.sr_return_amt > 20
),
combined AS (
  SELECT DISTINCT
    s.c_customer_id AS customer_id,
    s.i_item_id,
    s.ws_net_profit AS amount,
    'sale' AS event_type,
    ROW_NUMBER() OVER (PARTITION BY s.c_customer_id ORDER BY s.ws_net_profit DESC) AS rn
  FROM sales_base s
  CROSS JOIN LATERAL (
        SELECT i_current_price
        FROM item
        WHERE i_item_sk = s.ws_item_sk
        ORDER BY i_current_price DESC
        LIMIT 1
  ) AS top_price
  UNION ALL
  SELECT DISTINCT
    r.customer_id,
    r.i_item_id,
    -r.wr_return_amt AS amount,
    'return' AS event_type,
    ROW_NUMBER() OVER (PARTITION BY r.customer_id ORDER BY r.wr_return_amt DESC) AS rn
  FROM returns_base r
)
SELECT
  customer_id,
  i_item_id,
  amount,
  event_type,
  rn
FROM combined
WHERE rn <= 10
ORDER BY amount DESC
LIMIT 100
