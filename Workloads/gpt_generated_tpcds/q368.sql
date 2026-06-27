WITH sales AS (
  SELECT
    ws_order_number,
    ws_item_sk,
    ws_promo_sk,
    ws_ship_mode_sk,
    ws_web_site_sk,
    ws_bill_customer_sk,
    ws_quantity,
    ws_ext_sales_price,
    ws_net_profit,
    ws_sold_time_sk
  FROM web_sales
  WHERE ws_quantity > 0
),

sales_with_time AS (
  SELECT
    s.ws_order_number,
    s.ws_item_sk,
    s.ws_promo_sk,
    s.ws_ship_mode_sk,
    s.ws_web_site_sk,
    s.ws_bill_customer_sk,
    s.ws_quantity,
    s.ws_ext_sales_price,
    s.ws_net_profit
  FROM sales s
  JOIN time_dim t
    ON s.ws_sold_time_sk = t.t_time_sk
  WHERE t.t_shift = 'AM'
),

returns AS (
  SELECT
    wr_order_number,
    wr_item_sk,
    wr_return_quantity,
    wr_return_amt,
    wr_net_loss
  FROM web_returns
)
SELECT
  promotion.p_promo_name,
  ship_mode.sm_type,
  web_site.web_name,
  COUNT(DISTINCT sales_with_time.ws_bill_customer_sk) AS distinct_customers,
  SUM(sales_with_time.ws_quantity) AS total_quantity_sold,
  SUM(sales_with_time.ws_ext_sales_price) AS total_sales_amount,
  SUM(sales_with_time.ws_net_profit) AS total_net_profit,
  COALESCE(SUM(returns.wr_return_quantity), 0) AS total_quantity_returned,
  COALESCE(SUM(returns.wr_return_amt), 0) AS total_return_amount,
  COALESCE(SUM(returns.wr_net_loss), 0) AS total_return_loss
FROM sales_with_time
LEFT JOIN returns
  ON sales_with_time.ws_order_number = returns.wr_order_number
 AND sales_with_time.ws_item_sk = returns.wr_item_sk
JOIN promotion
  ON sales_with_time.ws_promo_sk = promotion.p_promo_sk
JOIN ship_mode
  ON sales_with_time.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk
JOIN web_site
  ON sales_with_time.ws_web_site_sk = web_site.web_site_sk
GROUP BY promotion.p_promo_name, ship_mode.sm_type, web_site.web_name
ORDER BY total_net_profit DESC
LIMIT 20
