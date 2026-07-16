SELECT i.i_brand,
       i.i_class,
       COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
       SUM(ss.ss_ext_sales_price) AS total_sales,
       SUM(ss.ss_net_profit) AS total_profit,
       AVG(ss.ss_ext_discount_amt) AS avg_discount,
       SUM(ss.ss_quantity) AS total_quantity,
       SUM(CASE WHEN ss.ss_coupon_amt > 0 THEN ss.ss_ext_sales_price ELSE 0 END) AS coupon_sales,
       RANK() OVER (ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
FROM item i
JOIN store_sales ss ON i.i_item_sk = ss.ss_item_sk
WHERE i.i_wholesale_cost > 5.00
  AND i.i_rec_end_date >= DATE '2000-01-01'
  AND ss.ss_sold_date_sk BETWEEN 2451545 AND 2451910
GROUP BY i.i_brand, i.i_class
HAVING SUM(ss.ss_ext_sales_price) > 10000
ORDER BY total_sales DESC
LIMIT 20
