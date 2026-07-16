SELECT
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_store_id,
    s.s_market_desc,
    wp.wp_type,
    d_page_creation.d_current_month AS page_creation_month,
    COUNT(DISTINCT ws.ws_order_number) AS total_orders,
    SUM(ws.ws_net_paid) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
    SUM(COALESCE(wr.wr_net_loss, 0)) AS total_return_loss,
    SUM(ws.ws_net_paid) - SUM(COALESCE(wr.wr_return_amt, 0)) AS net_sales_after_returns
FROM date_dim d_sales
JOIN web_sales ws
    ON ws.ws_sold_date_sk = d_sales.d_date_sk
JOIN store s
    ON s.s_closed_date_sk = d_sales.d_date_sk
JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_returned_date_sk = d_sales.d_date_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN date_dim d_page_creation
    ON wp.wp_creation_date_sk = d_page_creation.d_date_sk
WHERE d_sales.d_year = 2023
GROUP BY
    d_sales.d_year,
    d_sales.d_month_seq,
    s.s_store_id,
    s.s_market_desc,
    wp.wp_type,
    d_page_creation.d_current_month
ORDER BY net_sales_after_returns DESC
LIMIT 100
