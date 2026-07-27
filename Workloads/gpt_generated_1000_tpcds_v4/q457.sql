SELECT
    d_sold.d_year,
    i.i_category,
    s.s_state,
    cd_bill.cd_gender,
    cp.cp_type,
    SUM(ws.ws_net_paid_inc_ship) AS total_net_paid_inc_ship,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    AVG(i.i_current_price) AS avg_item_price,
    SUM(inv.inv_quantity_on_hand) AS total_qty_on_hand,
    MAX(wr.wr_return_amt) AS max_return_amount
FROM tpcds.web_sales ws
JOIN tpcds.date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN tpcds.date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN tpcds.item i
  ON ws.ws_item_sk = i.i_item_sk
JOIN tpcds.customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN tpcds.web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
JOIN tpcds.date_dim d_return
  ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN tpcds.inventory inv
  ON i.i_item_sk = inv.inv_item_sk
JOIN tpcds.date_dim d_inv
  ON inv.inv_date_sk = d_inv.d_date_sk
JOIN tpcds.store s
  ON s.s_closed_date_sk = d_ship.d_date_sk
JOIN tpcds.catalog_page cp
  ON cp.cp_start_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2001
  AND i.i_manufact_id IN (260, 479)
  AND i.i_current_price BETWEEN 5 AND 20
  AND cd_bill.cd_gender = 'M'
  AND cp.cp_type = 'monthly'
  AND s.s_state = 'CA'
  AND wp.wp_type = 'home'
GROUP BY
    d_sold.d_year,
    i.i_category,
    s.s_state,
    cd_bill.cd_gender,
    cp.cp_type
ORDER BY total_net_paid_inc_ship DESC
LIMIT 100
