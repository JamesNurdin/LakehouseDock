WITH combined_sales AS (
   SELECT cs.cs_bill_customer_sk AS customer_sk,
          cs.cs_net_paid AS net_paid,
          'catalog' AS sales_channel,
          cs.cs_order_number AS order_number,
          cs.cs_item_sk AS item_sk
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2001
     AND p.p_discount_active = 'Y'
   UNION ALL
   SELECT ws.ws_bill_customer_sk AS customer_sk,
          ws.ws_net_paid AS net_paid,
          'web' AS sales_channel,
          ws.ws_order_number AS order_number,
          ws.ws_item_sk AS item_sk
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   WHERE d.d_year = 2001
     AND p.p_discount_active = 'Y'
),
 top_customers AS (
   SELECT customer_sk, SUM(net_paid) AS total_sales
   FROM combined_sales
   GROUP BY customer_sk
   HAVING SUM(net_paid) > 5000
 ),
 aggregated AS (
   SELECT
       cs.customer_sk,
       c.c_first_name,
       c.c_last_name,
       cs.sales_channel,
       SUM(cs.net_paid) AS channel_sales,
       COUNT(DISTINCT cs.order_number) AS distinct_orders,
       COUNT(DISTINCT cs.item_sk) AS distinct_items,
       CASE WHEN tc.total_sales > 20000 THEN 'VIP' ELSE 'Regular' END AS customer_segment,
       (SELECT AVG(i_current_price) FROM item WHERE i_category = 'Books') AS avg_book_price
   FROM combined_sales cs
   JOIN top_customers tc ON cs.customer_sk = tc.customer_sk
   JOIN customer c ON cs.customer_sk = c.c_customer_sk
   GROUP BY
       cs.customer_sk,
       c.c_first_name,
       c.c_last_name,
       cs.sales_channel,
       tc.total_sales
 )
SELECT
   a.customer_sk,
   a.c_first_name,
   a.c_last_name,
   a.sales_channel,
   a.channel_sales,
   a.distinct_orders,
   a.distinct_items,
   a.customer_segment,
   a.avg_book_price,
   ROW_NUMBER() OVER (PARTITION BY a.sales_channel ORDER BY a.channel_sales DESC) AS channel_rank
FROM aggregated a
ORDER BY a.channel_sales DESC
LIMIT 100
