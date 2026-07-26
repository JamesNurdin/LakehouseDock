SELECT d_sold.d_month_seq,
       SUM(cs.cs_ext_sales_price) AS total_extended_sales,
       SUM(cs.cs_ext_discount_amt) AS total_discount,
       COALESCE(SUM(sr.sr_return_quantity), 0) AS total_return_qty,
       SUM(cs.cs_quantity) AS total_quantity_sold,
       CASE WHEN SUM(cs.cs_ext_sales_price) = 0 THEN 0 ELSE SUM(cs.cs_ext_discount_amt) / SUM(cs.cs_ext_sales_price) END AS discount_rate,
       RANK() OVER (ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS sales_rank,
       MIN(t_sold.t_hour) AS earliest_sale_hour,
       MAX(t_sold.t_hour) AS latest_sale_hour
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
LEFT JOIN store_returns sr ON sr.sr_returned_date_sk = d_sold.d_date_sk AND sr.sr_item_sk = cs.cs_item_sk
WHERE d_sold.d_month_seq % 2 = 0
GROUP BY d_sold.d_month_seq
HAVING SUM(cs.cs_quantity) > 1000
ORDER BY discount_rate ASC
