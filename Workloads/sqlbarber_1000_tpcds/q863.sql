SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_ext_tax,
    (ws.ws_ext_sales_price + ws.ws_ext_tax) AS total_sales_tax,
    CASE
        WHEN ws.ws_quantity > 10 THEN 'Bulk'
        ELSE 'Regular'
    END AS quantity_type,
    CASE
        WHEN wr.wr_return_quantity > 0 THEN wr.wr_return_amt * 0.9
        ELSE 0
    END AS adjusted_return_amt,
    (wr.wr_return_amt + wr.wr_return_tax) AS total_return,
    ws.ws_net_profit - wr.wr_net_loss AS net_profit_adjusted
FROM web_sales ws
JOIN web_returns wr
  ON ws.ws_item_sk = wr.wr_item_sk
 AND ws.ws_order_number = wr.wr_order_number
WHERE ws.ws_sold_date_sk = 2452062
  AND wr.wr_returned_date_sk = 2452753
