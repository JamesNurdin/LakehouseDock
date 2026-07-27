/*
Goal: Analyze the combined financial impact of catalog returns, store returns, and web sales for a specific fiscal quarter, focusing on a narrow range of wholesale costs and higher catalog fees. The query joins all four tables on the common date dimension, applies three realistic filter predicates, and aggregates key monetary measures by year and month.
*/
SELECT
    d.d_year,
    d.d_month_seq,
    COUNT(DISTINCT cr.cr_order_number) AS cnt_catalog_orders,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(ws.ws_ext_sales_price) AS total_web_sales,
    AVG(ws.ws_wholesale_cost) AS avg_web_wholesale_cost,
    MIN(ws.ws_ext_sales_price) AS min_web_sales_price,
    MAX(ws.ws_ext_sales_price) AS max_web_sales_price
FROM catalog_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN store_returns sr
  ON sr.sr_returned_date_sk = d.d_date_sk
JOIN web_sales ws
  ON ws.ws_sold_date_sk = d.d_date_sk
WHERE d.d_fy_quarter_seq = 3
  AND ws.ws_wholesale_cost BETWEEN 35.0 AND 55.0
  AND cr.cr_fee > 20.0
GROUP BY d.d_year, d.d_month_seq
ORDER BY d.d_year, d.d_month_seq
