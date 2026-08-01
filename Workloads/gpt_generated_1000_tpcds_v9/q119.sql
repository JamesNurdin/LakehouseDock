SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    i.i_item_id,
    i.i_product_name,
    SUM(ws.ws_ext_sales_price)          AS total_ext_sales,
    SUM(ws.ws_net_paid_inc_ship_tax)    AS total_net_paid,
    AVG(ws.ws_sales_price)              AS avg_sales_price,
    COUNT(DISTINCT ws.ws_order_number)  AS order_count,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_qty,
    SUM(COALESCE(wr.wr_return_amt, 0))      AS total_return_amount,
    ROW_NUMBER() OVER (ORDER BY SUM(ws.ws_net_paid_inc_ship_tax) DESC) AS row_num
FROM web_sales ws
INNER JOIN date_dim d_sold ON ws.ws_sold_date_sk = d_sold.d_date_sk
INNER JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
INNER JOIN item i ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
     AND ws.ws_item_sk      = wr.wr_item_sk
     AND wr.wr_return_tax  > 5
LEFT JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
WHERE d_sold.d_year = 2000
  AND i.i_manager_id IN (40, 23)
  AND i.i_current_price > 10
  AND ws.ws_quantity >= 2
  AND ws.ws_net_paid_inc_ship_tax > 500
GROUP BY d_sold.d_year,
         d_sold.d_month_seq,
         i.i_item_id,
         i.i_product_name
HAVING SUM(ws.ws_ext_sales_price) > 1000
   AND COUNT(DISTINCT ws.ws_order_number) >= 5
ORDER BY total_net_paid DESC
LIMIT 100
