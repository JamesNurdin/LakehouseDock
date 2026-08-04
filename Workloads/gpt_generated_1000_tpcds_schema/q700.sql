WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        d_sold.d_year,
        d_sold.d_month_seq,
        p.p_promo_name,
        p.p_channel_press,
        w.w_warehouse_id,
        w.w_city,
        s.s_store_id,
        s.s_state,
        cc.cc_call_center_id,
        cc.cc_state
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN store s
        ON s.s_closed_date_sk = d_sold.d_date_sk
    LEFT JOIN call_center cc
        ON cc.cc_closed_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001
      AND p.p_channel_press = 'N'
      AND w.w_city = 'Seattle'
      AND s.s_state = 'CA'
      AND cc.cc_state = 'CA'
),
returns AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        d_ret.d_year AS return_year
    FROM web_returns wr
    JOIN date_dim d_ret
        ON wr.wr_returned_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2001
),
high_profit_orders AS (
    SELECT ws_order_number
    FROM sales
    GROUP BY ws_order_number
    HAVING sum(ws_net_profit) > 5000
),
orders_with_returns AS (
    SELECT DISTINCT wr_order_number AS ws_order_number
    FROM returns
    WHERE wr_return_quantity > 0
),
target_orders AS (
    SELECT ws_order_number
    FROM high_profit_orders
    INTERSECT
    SELECT ws_order_number
    FROM orders_with_returns
)
SELECT
    sw.ws_order_number,
    sw.d_year,
    sw.p_promo_name,
    sw.w_warehouse_id,
    sw.s_store_id,
    sw.cc_call_center_id,
    sw.ws_quantity,
    sw.ws_ext_sales_price,
    sw.ws_net_profit,
    SUM(sw.ws_ext_sales_price) OVER (PARTITION BY sw.ws_order_number) AS total_order_sales,
    ROW_NUMBER() OVER (ORDER BY sw.ws_ext_sales_price DESC) AS global_row_num,
    RANK() OVER (PARTITION BY sw.p_promo_name ORDER BY sw.ws_net_profit DESC) AS promo_profit_rank,
    CASE
        WHEN sw.ws_net_profit > 1000 THEN 'HIGH'
        WHEN sw.ws_net_profit > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    la.running_total
FROM sales sw
JOIN returns rt
    ON rt.wr_order_number = sw.ws_order_number
   AND rt.wr_item_sk = sw.ws_item_sk
CROSS JOIN LATERAL (
    SELECT sum(ws2.ws_ext_sales_price) AS running_total
    FROM web_sales ws2
    WHERE ws2.ws_sold_date_sk <= sw.ws_sold_date_sk
) la
WHERE sw.ws_order_number IN (SELECT ws_order_number FROM target_orders)
GROUP BY
    sw.ws_order_number,
    sw.d_year,
    sw.p_promo_name,
    sw.w_warehouse_id,
    sw.s_store_id,
    sw.cc_call_center_id,
    sw.ws_quantity,
    sw.ws_ext_sales_price,
    sw.ws_net_profit,
    la.running_total
HAVING SUM(sw.ws_ext_sales_price) > 1000
ORDER BY sw.ws_ext_sales_price DESC
LIMIT 100
