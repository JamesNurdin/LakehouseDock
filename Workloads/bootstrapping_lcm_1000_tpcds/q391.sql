SELECT
    i.i_item_sk,
    i.i_product_name,
    d_return.d_date AS return_date,
    d_sold.d_date   AS sold_date,
    d_ship.d_date   AS ship_date,
    s.s_store_id,
    COUNT(DISTINCT cr.cr_order_number)            AS returns_count,
    SUM(cr.cr_return_amount)                      AS total_return_amount,
    COUNT(DISTINCT ws.ws_order_number)            AS sales_count,
    SUM(ws.ws_ext_sales_price)                    AS total_sales,
    SUM(ws.ws_net_profit)                         AS total_profit,
    AVG(i.i_current_price)                        AS avg_current_price,
    (SUM(ws.ws_quantity) - SUM(cr.cr_return_quantity)) AS net_quantity
FROM catalog_returns cr
JOIN date_dim d_return
  ON cr.cr_returned_date_sk = d_return.d_date_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
JOIN date_dim d_sold
  ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
  ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d_return.d_date_sk
WHERE d_return.d_year = 2020
  AND i.i_category = 'Electronics'
GROUP BY
    i.i_item_sk,
    i.i_product_name,
    d_return.d_date,
    d_sold.d_date,
    d_ship.d_date,
    s.s_store_id
ORDER BY total_return_amount DESC
LIMIT 100
