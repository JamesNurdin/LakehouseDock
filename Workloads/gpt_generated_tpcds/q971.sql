WITH sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_item_sk,
        ws.ws_quantity,
        ws.ws_ext_sales_price,
        ws.ws_ext_discount_amt,
        ws.ws_net_profit,
        ws.ws_sold_time_sk,
        ws.ws_promo_sk,
        ws.ws_ship_mode_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_warehouse_sk,
        ws.ws_web_page_sk
    FROM web_sales ws
),
returns_agg AS (
    SELECT
        wr.wr_order_number,
        wr.wr_item_sk,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        COUNT(*) AS return_line_cnt
    FROM web_returns wr
    GROUP BY wr.wr_order_number, wr.wr_item_sk
)
SELECT
    p.p_promo_name,
    sm.sm_type,
    t_sold.t_hour,
    hd.hd_buy_potential,
    COUNT(DISTINCT s.ws_order_number) AS num_orders,
    SUM(s.ws_quantity) AS total_quantity_sold,
    SUM(s.ws_ext_sales_price) AS total_sales_amount,
    SUM(s.ws_ext_discount_amt) AS total_discount_amount,
    SUM(s.ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT r.wr_order_number) AS num_returns,
    SUM(r.total_return_amt_inc_tax) AS total_return_amount,
    SUM(s.ws_ext_sales_price) - COALESCE(SUM(r.total_return_amt_inc_tax), 0) AS net_sales_after_returns
FROM sales s
JOIN promotion p ON s.ws_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON s.ws_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim t_sold ON s.ws_sold_time_sk = t_sold.t_time_sk
JOIN household_demographics hd ON s.ws_bill_hdemo_sk = hd.hd_demo_sk
JOIN warehouse w ON s.ws_warehouse_sk = w.w_warehouse_sk
JOIN web_page wp ON s.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN returns_agg r ON s.ws_order_number = r.wr_order_number
    AND s.ws_item_sk = r.wr_item_sk
WHERE t_sold.t_hour BETWEEN 9 AND 17
  AND p.p_discount_active = 'Y'
  AND sm.sm_type = 'AIR'
  AND wp.wp_type = 'PRODUCT'
GROUP BY
    p.p_promo_name,
    sm.sm_type,
    t_sold.t_hour,
    hd.hd_buy_potential
ORDER BY net_sales_after_returns DESC
LIMIT 100
