SELECT wr.wr_order_number,
       i.i_item_id,
       i.i_product_name,
       CASE WHEN i.i_current_price > 2.77 THEN i.i_current_price * 86.00 ELSE i.i_current_price - 86.00 END AS price_adj,
       i.i_wholesale_cost * 62.78 AS wholesale_cost_markup,
       (i.i_current_price - i.i_wholesale_cost) / i.i_current_price * 100 AS margin_percent,
       CASE WHEN wr.wr_return_quantity > 57 THEN 'High Return' ELSE 'Low Return' END AS return_category
FROM web_returns wr
JOIN item i ON wr.wr_item_sk = i.i_item_sk
WHERE i.i_category = 'Jewelry                                           ' AND wr.wr_returned_date_sk = 2451878
