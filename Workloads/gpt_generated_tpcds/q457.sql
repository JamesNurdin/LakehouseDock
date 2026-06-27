/* Promotion performance by month and warehouse state */
SELECT
    p.p_promo_id,
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_month_seq AS month_seq,
    w.w_state,
    SUM(ws.ws_ext_sales_price)          AS total_sales,
    SUM(ws.ws_net_profit)               AS total_profit,
    COUNT(DISTINCT ws.ws_order_number)  AS order_cnt,
    SUM(ws.ws_quantity)                 AS total_quantity,
    COALESCE(SUM(wr.wr_return_amt), 0)   AS total_returns,
    COALESCE(SUM(wr.wr_return_quantity), 0) AS total_return_qty,
    CASE
        WHEN SUM(ws.ws_ext_sales_price) > 0 THEN COALESCE(SUM(wr.wr_return_amt), 0) / SUM(ws.ws_ext_sales_price)
        ELSE NULL
    END                                 AS return_rate
FROM web_sales ws
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN date_dim d_sold
    ON ws.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_start
    ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end
    ON p.p_end_date_sk = d_end.d_date_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
WHERE d_sold.d_date BETWEEN d_start.d_date AND d_end.d_date
GROUP BY
    p.p_promo_id,
    p.p_promo_name,
    d_sold.d_year,
    d_sold.d_month_seq,
    w.w_state
ORDER BY total_sales DESC
LIMIT 100
