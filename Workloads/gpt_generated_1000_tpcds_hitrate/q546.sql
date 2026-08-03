WITH base_sales AS (
  SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    ws.ws_sold_time_sk,
    ws.ws_item_sk,
    ws.ws_sales_price,
    ws.ws_quantity,
    ws.ws_net_profit,
    ws.ws_ext_sales_price,
    ws.ws_coupon_amt,
    ws.ws_ship_mode_sk,
    ws.ws_bill_customer_sk,
    ws.ws_bill_cdemo_sk,
    ws.ws_bill_addr_sk,
    c.c_customer_id,
    c.c_last_name,
    c.c_preferred_cust_flag,
    cd.cd_gender,
    ca.ca_state,
    sm.sm_carrier,
    td.t_hour
  FROM web_sales ws
  JOIN time_dim td
    ON ws.ws_sold_time_sk = td.t_time_sk
  JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  WHERE ws.ws_sales_price > 20
    AND ws.ws_quantity >= 2
    AND sm.sm_carrier = 'MSC'
    AND ca.ca_state = 'CA'
    AND cd.cd_gender = 'M'
    AND td.t_hour BETWEEN 9 AND 17
)
SELECT
  bs.ws_order_number,
  bs.ws_sold_date_sk,
  bs.c_customer_id,
  bs.c_last_name,
  bs.cd_gender,
  bs.ca_state,
  bs.sm_carrier,
  bs.ws_sales_price,
  bs.ws_ext_sales_price,
  CASE WHEN bs.ws_sales_price > 100 THEN 'High' ELSE 'Low' END AS price_category,
  wr.ret_qty,
  wr.ret_amt,
  RANK() OVER (PARTITION BY bs.sm_carrier ORDER BY bs.ws_net_profit DESC) AS profit_rank,
  ROW_NUMBER() OVER (PARTITION BY bs.ws_bill_customer_sk ORDER BY bs.ws_sold_date_sk DESC) AS recent_purchase_num
FROM base_sales bs
CROSS JOIN LATERAL (
  SELECT
    wr.wr_return_quantity AS ret_qty,
    wr.wr_return_amt AS ret_amt
  FROM web_returns wr
  WHERE wr.wr_order_number = bs.ws_order_number
    AND wr.wr_item_sk = bs.ws_item_sk
) wr
ORDER BY profit_rank ASC, bs.ws_net_profit DESC
LIMIT 100
