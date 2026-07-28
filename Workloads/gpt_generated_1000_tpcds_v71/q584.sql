/*
Goal: Compute daily sales and return metrics for 2001 content web pages, aggregating total sales, profit, order counts, large‑quantity sales, and high‑fee returns. The query joins all six TPC‑DS tables, re‑uses date_dim, time_dim and web_page under different aliases to achieve at least nine join clauses, uses a CTE, a scalar subquery, and CASE expressions, and returns the top 100 rows by sales amount.
*/
WITH sales_filtered AS (
    SELECT *
    FROM web_sales
    WHERE ws_quantity > 0
)
SELECT
    d_sold.d_date               AS sold_date,
    d_ship.d_date               AS ship_date,
    t_sold.t_hour               AS sold_hour,
    wp_sales.wp_url             AS page_url,
    wp_sales.wp_type            AS page_type,
    SUM(ws_f.ws_ext_sales_price)        AS total_sales,
    SUM(ws_f.ws_net_profit)             AS total_profit,
    COUNT(DISTINCT ws_f.ws_order_number) AS orders,
    SUM(CASE WHEN ws_f.ws_quantity > 5 THEN ws_f.ws_ext_sales_price ELSE 0 END) AS large_qty_sales,
    SUM(CASE WHEN r.r_reason_desc IS NOT NULL THEN wr.wr_return_amt ELSE 0 END) AS total_return_amount,
    COUNT(CASE WHEN wr.wr_fee > (SELECT AVG(wr2.wr_fee) FROM web_returns wr2) THEN 1 END) AS high_fee_return_cnt
FROM sales_filtered ws_f
JOIN date_dim d_sold   ON ws_f.ws_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship   ON ws_f.ws_ship_date_sk = d_ship.d_date_sk
JOIN time_dim t_sold   ON ws_f.ws_sold_time_sk = t_sold.t_time_sk
JOIN web_page wp_sales ON ws_f.ws_web_page_sk = wp_sales.wp_web_page_sk
LEFT JOIN web_returns wr
       ON ws_f.ws_order_number = wr.wr_order_number
      AND ws_f.ws_item_sk      = wr.wr_item_sk
JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
JOIN time_dim t_return ON wr.wr_returned_time_sk = t_return.t_time_sk
JOIN web_page wp_return ON wr.wr_web_page_sk = wp_return.wp_web_page_sk
JOIN reason r           ON wr.wr_reason_sk = r.r_reason_sk
WHERE d_sold.d_year = 2001
  AND wp_sales.wp_type = 'Content'
GROUP BY
    d_sold.d_date,
    d_ship.d_date,
    t_sold.t_hour,
    wp_sales.wp_url,
    wp_sales.wp_type
ORDER BY total_sales DESC
LIMIT 100
