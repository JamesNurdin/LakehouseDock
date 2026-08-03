SELECT
    cs.cs_list_price,
    COUNT(*) AS return_count,
    SUM(cr.cr_refunded_cash) AS total_refunded_cash,
    AVG(cs.cs_ext_discount_amt) AS avg_discount
FROM tpcds.catalog_returns AS cr
JOIN tpcds.catalog_sales AS cs
  ON cr.cr_order_number = cs.cs_order_number
WHERE cr.cr_refunded_cash > 100
  AND cs.cs_list_price BETWEEN 80 AND 200
GROUP BY cs.cs_list_price
ORDER BY total_refunded_cash DESC
LIMIT 20
