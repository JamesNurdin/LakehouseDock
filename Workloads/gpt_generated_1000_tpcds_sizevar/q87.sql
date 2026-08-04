WITH filtered AS (
    SELECT
        cr.cr_return_amount,
        cr.cr_fee,
        cr.cr_return_ship_cost,
        cr.cr_order_number,
        cp.cp_department,
        hd.hd_buy_potential,
        td.t_hour,
        wp.wp_type,
        ws.ws_sales_price,
        ws.ws_net_profit
    FROM catalog_returns cr
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_sales ws ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                         AND wr.wr_item_sk = ws.ws_item_sk
    WHERE cr.cr_return_amount > 1000
      AND hd.hd_buy_potential = '1001-5000'
      AND wr.wr_reason_sk IN (23, 33)
      AND ws.ws_sales_price BETWEEN 100 AND 500
      AND td.t_hour BETWEEN 9 AND 17
)
SELECT
    cp_department,
    hd_buy_potential,
    t_hour,
    wp_type,
    SUM(cr_return_amount) AS total_return_amount,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT cr_order_number) AS distinct_return_orders,
    AVG(cr_fee) AS avg_return_fee,
    MIN(cr_return_ship_cost) AS min_return_ship_cost,
    MAX(cr_return_ship_cost) AS max_return_ship_cost
FROM filtered
GROUP BY cp_department, hd_buy_potential, t_hour, wp_type
ORDER BY total_return_amount DESC
LIMIT 100
