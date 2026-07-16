SELECT
    s.s_store_id,
    s.s_market_desc,
    d_sold.d_year,
    d_sold.d_quarter_name,
    wp.wp_type,
    COUNT(DISTINCT ws.ws_order_number) AS order_cnt,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    SUM(ws.ws_quantity) AS total_quantity,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
    ROUND(
        CASE WHEN SUM(ws.ws_quantity) > 0
             THEN 100.0 * SUM(COALESCE(wr.wr_return_quantity, 0)) / SUM(ws.ws_quantity)
             ELSE 0
        END,
        2
    ) AS return_rate_percent,
    MIN(d_page_creation.d_date) AS earliest_page_creation_date,
    MAX(d_page_access.d_date) AS latest_page_access_date,
    MIN(d_ship.d_month_seq) AS ship_month_seq
FROM web_sales ws
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
       AND wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_market_desc,
    d_sold.d_year,
    d_sold.d_quarter_name,
    wp.wp_type
ORDER BY total_net_profit DESC
LIMIT 100
