WITH sales AS (
    SELECT
        ws.ws_sold_date_sk,
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_item_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_site_sk
    FROM web_sales ws
)
SELECT
    d_sold.d_year,
    d_sold.d_month_seq,
    ws_site.web_name,
    i.i_category,
    sm.sm_type,
    SUM(sales.ws_net_profit) AS total_sales_profit,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    SUM(sales.ws_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit_after_returns,
    COUNT(DISTINCT sales.ws_order_number) AS orders,
    COUNT(DISTINCT wr.wr_order_number) AS returns
FROM sales
JOIN date_dim d_sold ON sales.ws_sold_date_sk = d_sold.d_date_sk
JOIN web_site ws_site ON sales.ws_web_site_sk = ws_site.web_site_sk
JOIN item i ON sales.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON sales.ws_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN web_returns wr ON sales.ws_order_number = wr.wr_order_number
WHERE d_sold.d_year = 2001
GROUP BY d_sold.d_year, d_sold.d_month_seq, ws_site.web_name, i.i_category, sm.sm_type
ORDER BY d_sold.d_year, d_sold.d_month_seq, ws_site.web_name, i.i_category, sm.sm_type
