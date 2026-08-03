WITH cat_data AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_time_sk,
    cs.cs_ship_mode_sk AS cs_ship_mode_sk,
    cs.cs_bill_customer_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cr.cr_return_quantity,
    cr.cr_return_amount,
    c.c_customer_sk,
    ca.ca_county,
    hd.hd_vehicle_count,
    sm.sm_ship_mode_id,
    td.t_sub_shift
  FROM catalog_sales cs
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
  WHERE td.t_sub_shift = 'night'
    AND ca.ca_county = 'Williams County'
    AND hd.hd_vehicle_count >= 2
),
web_data AS (
  SELECT
    ws.ws_order_number,
    ws.ws_sold_time_sk,
    ws.ws_ship_mode_sk,
    ws.ws_bill_customer_sk,
    ws.ws_quantity,
    ws.ws_net_paid,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    c.c_customer_sk AS cust_sk,
    ca.ca_county AS wr_county,
    hd.hd_vehicle_count AS wr_vehicle_cnt,
    sm.sm_ship_mode_id AS wr_ship_mode_id,
    td2.t_sub_shift AS wr_sub_shift
  FROM web_sales ws
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  JOIN customer c
    ON ws.ws_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca
    ON ws.ws_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  JOIN ship_mode sm
    ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN time_dim td2
    ON ws.ws_sold_time_sk = td2.t_time_sk
  WHERE td2.t_sub_shift = 'night'
    AND ca.ca_state = 'CA'
    AND hd.hd_vehicle_count >= 2
    AND ws.ws_quantity > 5
)
SELECT
  cat_data.cs_ship_mode_sk AS ship_mode_key,
  sm.sm_ship_mode_id,
  cat_data.t_sub_shift,
  COUNT(DISTINCT cat_data.cs_order_number) AS catalog_orders,
  SUM(cat_data.cs_quantity) AS total_catalog_qty,
  SUM(cat_data.cs_net_paid) AS total_catalog_net,
  SUM(cat_data.cr_return_quantity) AS total_catalog_returns,
  SUM(cat_data.cr_return_amount) AS total_catalog_return_amount,
  COUNT(DISTINCT web_data.ws_order_number) AS web_orders,
  SUM(web_data.ws_quantity) AS total_web_qty,
  SUM(web_data.ws_net_paid) AS total_web_net,
  SUM(web_data.wr_return_quantity) AS total_web_returns,
  SUM(web_data.wr_return_amt) AS total_web_return_amount,
  CASE
    WHEN SUM(cat_data.cs_quantity) > (SELECT AVG(cs_quantity) FROM catalog_sales)
    THEN 'CAT_HIGH_QTY'
    ELSE 'CAT_LOW_QTY'
  END AS catalog_qty_category,
  CASE
    WHEN SUM(web_data.ws_quantity) > (SELECT AVG(ws_quantity) FROM web_sales)
    THEN 'WEB_HIGH_QTY'
    ELSE 'WEB_LOW_QTY'
  END AS web_qty_category
FROM cat_data
JOIN web_data
  ON cat_data.c_customer_sk = web_data.cust_sk
 AND cat_data.ca_county = web_data.wr_county
 AND cat_data.cs_ship_mode_sk = web_data.ws_ship_mode_sk
JOIN ship_mode sm
  ON cat_data.cs_ship_mode_sk = sm.sm_ship_mode_sk
GROUP BY
  cat_data.cs_ship_mode_sk,
  sm.sm_ship_mode_id,
  cat_data.t_sub_shift
ORDER BY total_catalog_net DESC
LIMIT 100
