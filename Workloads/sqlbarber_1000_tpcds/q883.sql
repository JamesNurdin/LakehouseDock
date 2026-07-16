SELECT
    ws.ws_order_number,
    CASE
        WHEN wr.wr_return_quantity > 72 THEN 'High Return'
        ELSE 'Low Return'
    END AS return_quantity_category,
    ws.ws_ext_sales_price - ws.ws_ext_discount_amt AS net_sales,
    wr.wr_return_amt + wr.wr_return_tax AS total_return_amount,
    CASE
        WHEN ws.ws_net_profit > 0 THEN ws.ws_net_profit
        ELSE 0
    END AS profit_or_zero,
    ws.ws_ext_sales_price * 0.1 AS ten_percent_sales,
    wr.wr_return_quantity * ws.ws_wholesale_cost AS cost_of_returned_items,
    ws.ws_ext_sales_price - wr.wr_return_amt AS sales_minus_return,
    CASE
        WHEN ws.ws_sold_date_sk = 2452312 THEN 'Sold on specific date'
        ELSE 'Other date'
    END AS sold_date_category
FROM web_returns wr
JOIN web_sales ws ON wr.wr_item_sk = ws.ws_item_sk
WHERE ws.ws_sold_date_sk = 2452177
  AND ws.ws_quantity > 20
