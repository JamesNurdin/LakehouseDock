WITH filtered_data AS (
    SELECT
        ws.ws_web_page_sk,
        wp.wp_web_page_id,
        t.t_hour,
        ws.ws_ext_sales_price,
        ws.ws_ext_wholesale_cost,
        ws.ws_ext_ship_cost,
        sr.sr_refunded_cash,
        sr.sr_store_credit
    FROM web_sales ws
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN store_returns sr
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE t.t_hour BETWEEN 9 AND 17                                 -- business hours
      AND ws.ws_ext_wholesale_cost > 500.00                         -- high wholesale cost
      AND ws.ws_ext_ship_cost BETWEEN 100.00 AND 2000.00            -- reasonable shipping cost
      AND sr.sr_refunded_cash > 20.00                               -- non‑trivial refunds
      AND sr.sr_store_credit < 1000.00                             -- limited store credit
)
SELECT
    wp_web_page_id,
    t_hour,
    SUM(ws_ext_sales_price)                         AS total_sales,
    SUM(sr_refunded_cash)                           AS total_refunds,
    SUM(ws_ext_sales_price) - SUM(sr_refunded_cash) AS net_sales,
    RANK() OVER (PARTITION BY t_hour ORDER BY SUM(ws_ext_sales_price) - SUM(sr_refunded_cash) DESC) AS sales_rank
FROM filtered_data
GROUP BY
    wp_web_page_id,
    t_hour
ORDER BY
    t_hour,
    net_sales DESC
LIMIT 100
