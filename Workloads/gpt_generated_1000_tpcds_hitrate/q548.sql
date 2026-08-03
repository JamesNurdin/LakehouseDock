WITH sales_with_promo AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_sold_time_sk,
        ws.ws_promo_sk,
        p.p_promo_name,
        p.p_channel_dmail,
        p.p_channel_email,
        t.t_hour,
        t.t_minute
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE p.p_channel_dmail = 'Y'
      AND t.t_hour BETWEEN 8 AND 12
),
returns_filtered AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_amt,
        wr.wr_return_quantity,
        wr.wr_returned_time_sk,
        t_ret.t_hour AS ret_hour
    FROM web_returns wr
    JOIN time_dim t_ret ON wr.wr_returned_time_sk = t_ret.t_time_sk
    WHERE wr.wr_return_amt > 50
),
all_return_orders AS (
    SELECT DISTINCT wr_order_number AS order_number
    FROM web_returns
),
high_return_orders AS (
    SELECT DISTINCT wr_order_number AS order_number
    FROM web_returns
    WHERE wr_return_amt > 200
),
eligible_orders AS (
    SELECT order_number FROM all_return_orders
    EXCEPT
    SELECT order_number FROM high_return_orders
)
SELECT
    swp.ws_order_number,
    swp.p_promo_name,
    swp.t_hour AS sale_hour,
    swp.ws_quantity,
    swp.ws_ext_sales_price,
    rf.ret_hour,
    rf.wr_return_amt,
    rf.wr_return_quantity,
    ROW_NUMBER() OVER (PARTITION BY swp.p_promo_name ORDER BY swp.ws_ext_sales_price DESC) AS promo_sale_rank,
    LAG(swp.ws_ext_sales_price) OVER (PARTITION BY swp.p_promo_name ORDER BY swp.ws_sold_time_sk) AS prev_sale_price,
    SUM(rf.wr_return_amt) OVER (PARTITION BY swp.ws_order_number) AS total_return_for_order
FROM sales_with_promo swp
JOIN returns_filtered rf
  ON swp.ws_order_number = rf.wr_order_number
 AND swp.ws_item_sk = rf.wr_item_sk
WHERE swp.ws_net_profit > 0
  AND swp.ws_order_number IN (SELECT order_number FROM eligible_orders)
  AND EXISTS (
        SELECT 1 FROM time_dim td_check WHERE td_check.t_hour = rf.ret_hour AND td_check.t_meal_time = 'Lunch'
    )
ORDER BY swp.ws_ext_sales_price DESC
LIMIT 100
