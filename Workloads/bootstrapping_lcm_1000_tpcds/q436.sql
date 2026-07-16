SELECT
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_quarter_name,
    wp.wp_type,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_net_profit,
    SUM(ws.ws_ext_discount_amt) AS total_discount,
    SUM(ws.ws_quantity) AS total_quantity_sold,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_return_quantity, 0)) AS total_return_quantity,
    CASE
        WHEN SUM(ws.ws_quantity) > 0
        THEN SUM(COALESCE(wr.wr_return_quantity, 0)) * 1.0 / SUM(ws.ws_quantity)
        ELSE 0
    END AS return_rate,
    AVG(ws.ws_sales_price) AS avg_sales_price,
    MAX(d_return.d_date) AS last_return_date,
    MIN(d_page_creation.d_date) AS page_creation_date,
    MAX(d_page_access.d_date) AS page_last_access_date
FROM web_sales ws
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
    AND ws.ws_item_sk = wr.wr_item_sk
    AND wp.wp_web_page_sk = wr.wr_web_page_sk
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship
    ON ws.ws_ship_date_sk = d_ship.d_date_sk
LEFT JOIN date_dim d_return
    ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
JOIN date_dim d_page_access
    ON wp.wp_access_date_sk = d_page_access.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2022
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_sold.d_year,
    d_sold.d_quarter_name,
    wp.wp_type
ORDER BY total_sales DESC
LIMIT 100
