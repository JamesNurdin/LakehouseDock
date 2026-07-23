WITH filtered_sales AS (
    SELECT ws.ws_sold_date_sk,
           ws.ws_sold_time_sk,
           ws.ws_item_sk,
           ws.ws_order_number,
           ws.ws_quantity,
           ws.ws_sales_price,
           ws.ws_ext_sales_price,
           ws.ws_net_profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    d.d_month_seq AS month_seq,
    s.s_store_name,
    cp.cp_department,
    CASE WHEN ws.ws_sales_price > 100 THEN 'Premium' ELSE 'Standard' END AS price_tier,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_quantity) AS total_quantity,
    AVG(ws.ws_net_profit) AS avg_profit,
    COUNT(DISTINCT ws.ws_order_number) AS distinct_orders,
    SUM(CASE WHEN wr.wr_return_amt IS NOT NULL THEN wr.wr_return_amt ELSE 0 END) AS total_return_amount,
    COUNT(wr.wr_return_quantity) AS return_count,
    (SELECT SUM(wr2.wr_return_amt)
     FROM web_returns wr2
     JOIN date_dim d2 ON wr2.wr_returned_date_sk = d2.d_date_sk
     WHERE d2.d_year = 2001) AS total_returns_year
FROM filtered_sales ws
JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
JOIN store s ON s.s_closed_date_sk = d.d_date_sk
JOIN catalog_page cp ON cp.cp_start_date_sk = d.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk AND wr.wr_order_number = ws.ws_order_number
WHERE t.t_hour BETWEEN 9 AND 17
  AND s.s_state = 'CA'
  AND cp.cp_department = 'Electronics'
GROUP BY d.d_month_seq,
         s.s_store_name,
         cp.cp_department,
         CASE WHEN ws.ws_sales_price > 100 THEN 'Premium' ELSE 'Standard' END
ORDER BY total_sales DESC
LIMIT 100
