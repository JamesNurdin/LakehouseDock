SELECT
    i.i_brand AS brand,
    d_sold.d_year AS sales_year,
    CASE WHEN cd_sold.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_category,
    CASE WHEN hd_sold.hd_buy_potential = '0-500' THEN 'Low'
         WHEN hd_sold.hd_buy_potential = '501-1000' THEN 'Medium'
         ELSE 'High' END AS buy_potential_category,
    SUM(ss.ss_quantity) AS total_store_quantity,
    SUM(ss.ss_net_profit) AS total_store_net_profit,
    SUM(ws.ws_quantity) AS total_web_quantity,
    SUM(ws.ws_net_profit) AS total_web_net_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount
FROM store_sales ss
JOIN date_dim d_sold
  ON ss.ss_sold_date_sk = d_sold.d_date_sk
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN customer_demographics cd_sold
  ON ss.ss_cdemo_sk = cd_sold.cd_demo_sk
JOIN household_demographics hd_sold
  ON ss.ss_hdemo_sk = hd_sold.hd_demo_sk
JOIN inventory inv
  ON inv.inv_item_sk = i.i_item_sk
 AND inv.inv_date_sk = d_sold.d_date_sk
JOIN warehouse w
  ON inv.inv_warehouse_sk = w.w_warehouse_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_ws_sold
  ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim d_ws_ship
  ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN customer_demographics cd_bill
  ON ws.ws_bill_cdemo_sk = cd_bill.cd_demo_sk
JOIN household_demographics hd_bill
  ON ws.ws_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN customer_demographics cd_ship
  ON ws.ws_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship
  ON ws.ws_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN web_page wp
  ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN warehouse w_ws
  ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
FULL OUTER JOIN web_returns wr
  ON ws.ws_order_number = wr.wr_order_number
 AND ws.ws_item_sk = wr.wr_item_sk
LEFT JOIN date_dim d_wr_returned
  ON wr.wr_returned_date_sk = d_wr_returned.d_date_sk
LEFT JOIN customer_demographics cd_refund
  ON wr.wr_refunded_cdemo_sk = cd_refund.cd_demo_sk
LEFT JOIN household_demographics hd_refund
  ON wr.wr_refunded_hdemo_sk = hd_refund.hd_demo_sk
LEFT JOIN customer_demographics cd_return
  ON wr.wr_returning_cdemo_sk = cd_return.cd_demo_sk
LEFT JOIN household_demographics hd_return
  ON wr.wr_returning_hdemo_sk = hd_return.hd_demo_sk
LEFT JOIN web_page wp_wr
  ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
WHERE d_sold.d_date >= DATE '1998-01-01'
  AND d_sold.d_date < DATE '1999-01-01'
GROUP BY
    i.i_brand,
    d_sold.d_year,
    CASE WHEN cd_sold.cd_gender = 'M' THEN 'Male' ELSE 'Female' END,
    CASE WHEN hd_sold.hd_buy_potential = '0-500' THEN 'Low'
         WHEN hd_sold.hd_buy_potential = '501-1000' THEN 'Medium'
         ELSE 'High' END
ORDER BY (total_store_net_profit + total_web_net_profit) DESC
