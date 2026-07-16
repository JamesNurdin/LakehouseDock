SELECT
    d_cr.d_year,
    d_cr.d_month_seq,
    s.s_state,
    CASE 
        WHEN d_cr.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_cr.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_cr.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END AS quarter,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_orders,
    SUM(cr.cr_return_amount) AS catalog_return_amount,
    SUM(cr.cr_net_loss) AS catalog_net_loss,
    COUNT(DISTINCT ws.ws_order_number) AS web_sales_orders,
    SUM(ws.ws_ext_sales_price) AS web_sales_amount,
    SUM(ws.ws_net_profit) AS web_sales_net_profit,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_orders,
    SUM(wr.wr_return_amt) AS web_return_amount,
    SUM(wr.wr_net_loss) AS web_return_net_loss,
    CASE 
        WHEN SUM(ws.ws_ext_sales_price) > 0 THEN SUM(wr.wr_return_amt) / SUM(ws.ws_ext_sales_price)
        ELSE NULL
    END AS return_to_sales_ratio,
    SUM(cr.cr_return_amount) - SUM(wr.wr_return_amt) AS diff_return_amount
FROM catalog_returns cr
JOIN date_dim d_cr ON cr.cr_returned_date_sk = d_cr.d_date_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d_cr.d_date_sk
JOIN web_sales ws ON ws.ws_item_sk = wr.wr_item_sk
    AND ws.ws_order_number = wr.wr_order_number
JOIN date_dim d_ws_sold ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
JOIN date_dim d_ws_ship ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_cr.d_date_sk
GROUP BY
    d_cr.d_year,
    d_cr.d_month_seq,
    s.s_state,
    CASE 
        WHEN d_cr.d_month_seq BETWEEN 1 AND 3 THEN 'Q1'
        WHEN d_cr.d_month_seq BETWEEN 4 AND 6 THEN 'Q2'
        WHEN d_cr.d_month_seq BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END
ORDER BY d_cr.d_year, d_cr.d_month_seq, s.s_state
LIMIT 100
