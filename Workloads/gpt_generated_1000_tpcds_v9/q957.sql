WITH sales_returns AS (
  SELECT
    ws.ws_order_number,
    ws.ws_item_sk,
    ws.ws_quantity,
    ws.ws_ext_sales_price,
    ws.ws_ext_list_price,
    ws.ws_ship_mode_sk,
    ws.ws_net_profit,
    wr.wr_return_quantity,
    wr.wr_return_amt,
    wr.wr_fee,
    i.i_category,
    i.i_manager_id,
    i.i_product_name,
    i.i_current_price,
    i.i_rec_start_date
  FROM web_sales ws
  JOIN item i
    ON ws.ws_item_sk = i.i_item_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
  WHERE i.i_category = 'Electronics'
    AND i.i_manager_id IN (3, 44, 63)
    AND ws.ws_ship_mode_sk IN (4, 8, 12)
    AND ws.ws_ext_list_price > 2000
    AND wr.wr_fee > 20
    AND i.i_rec_start_date >= DATE '2000-01-01'
)
SELECT
  sr.ws_order_number,
  sr.ws_item_sk,
  sr.i_product_name,
  sr.i_category,
  sr.i_manager_id,
  sr.ws_ext_sales_price,
  sr.ws_net_profit,
  CASE
    WHEN sr.ws_net_profit > 500 THEN 'High Profit'
    WHEN sr.ws_net_profit > 0 THEN 'Medium Profit'
    ELSE 'Low Profit'
  END AS profit_category,
  RANK() OVER (PARTITION BY sr.i_category ORDER BY sr.ws_net_profit DESC) AS profit_rank_in_category,
  (SELECT SUM(wr2.wr_return_amt)
   FROM web_returns wr2
   WHERE wr2.wr_item_sk = sr.ws_item_sk) AS total_return_amount_for_item
FROM sales_returns sr
ORDER BY sr.ws_net_profit DESC
LIMIT 100
