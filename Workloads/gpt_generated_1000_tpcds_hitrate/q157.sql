WITH union_sales AS (
    SELECT c.c_customer_id AS customer_id,
           cs.cs_ext_sales_price AS sales_amount,
           'Catalog' AS channel,
           c.c_customer_sk AS cust_sk
    FROM catalog_sales cs
    JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2451179
    UNION ALL
    SELECT c.c_customer_id,
           ws.ws_ext_sales_price,
           'Web',
           c.c_customer_sk
    FROM web_sales ws
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2451179
)
SELECT us.customer_id,
       SUM(us.sales_amount) AS total_sales,
       COUNT(DISTINCT us.channel) AS channels_used
FROM union_sales us
WHERE EXISTS (
    SELECT 1
    FROM store_sales ss
    WHERE ss.ss_customer_sk = us.cust_sk
)
GROUP BY us.customer_id
HAVING SUM(us.sales_amount) > (
    SELECT AVG(total_sales)
    FROM (
        SELECT us2.customer_id,
               SUM(us2.sales_amount) AS total_sales
        FROM union_sales us2
        GROUP BY us2.customer_id
    ) avg_sub
)
ORDER BY total_sales DESC
LIMIT 100
