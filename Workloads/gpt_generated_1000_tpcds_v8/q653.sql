WITH sales_summary AS (
    SELECT cs.cs_bill_customer_sk AS cust_sk,
           d.d_year,
           SUM(cs.cs_ext_sales_price) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rank_year
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
    GROUP BY cs.cs_bill_customer_sk, d.d_year
)
SELECT *
FROM (
    SELECT cs.cs_sold_date_sk AS date_sk,
           cs.cs_bill_customer_sk AS cust_sk,
           cs.cs_ext_sales_price AS sales,
           CASE WHEN cs.cs_quantity > 5 THEN 'Large' ELSE 'Small' END AS size_flag,
           LAG(cs.cs_ext_sales_price) OVER (PARTITION BY cs.cs_bill_customer_sk ORDER BY cs.cs_sold_date_sk) AS prev_sales,
           (
               SELECT MAX(ws2.ws_ext_sales_price)
               FROM web_sales ws2
               WHERE ws2.ws_bill_customer_sk = cs.cs_bill_customer_sk
                 AND ws2.ws_sold_date_sk = cs.cs_sold_date_sk
           ) AS max_web_sales,
           (
               SELECT ss.total_sales
               FROM sales_summary ss
               WHERE ss.cust_sk = cs.cs_bill_customer_sk
                 AND ss.d_year = 2001
           ) AS cust_year_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001

    UNION

    SELECT ws.ws_sold_date_sk AS date_sk,
           ws.ws_bill_customer_sk AS cust_sk,
           ws.ws_ext_sales_price AS sales,
           CASE WHEN ws.ws_quantity > 5 THEN 'Large' ELSE 'Small' END AS size_flag,
           LAG(ws.ws_ext_sales_price) OVER (PARTITION BY ws.ws_bill_customer_sk ORDER BY ws.ws_sold_date_sk) AS prev_sales,
           (
               SELECT MAX(cs2.cs_ext_sales_price)
               FROM catalog_sales cs2
               WHERE cs2.cs_bill_customer_sk = ws.ws_bill_customer_sk
                 AND cs2.cs_sold_date_sk = ws.ws_sold_date_sk
           ) AS max_web_sales,
           (
               SELECT ss.total_sales
               FROM sales_summary ss
               WHERE ss.cust_sk = ws.ws_bill_customer_sk
                 AND ss.d_year = 2001
           ) AS cust_year_sales
    FROM web_sales ws
    JOIN date_dim d2 ON ws.ws_sold_date_sk = d2.d_date_sk
    WHERE d2.d_year = 2001
) AS unioned
INTERSECT
SELECT ws3.ws_sold_date_sk AS date_sk,
       ws3.ws_bill_customer_sk AS cust_sk,
       ws3.ws_ext_sales_price AS sales,
       CASE WHEN ws3.ws_quantity > 5 THEN 'Large' ELSE 'Small' END AS size_flag,
       LAG(ws3.ws_ext_sales_price) OVER (PARTITION BY ws3.ws_bill_customer_sk ORDER BY ws3.ws_sold_date_sk) AS prev_sales,
       NULL AS max_web_sales,
       (
           SELECT ss.total_sales
           FROM sales_summary ss
           WHERE ss.cust_sk = ws3.ws_bill_customer_sk
             AND ss.d_year = 2001
       ) AS cust_year_sales
FROM web_sales ws3
JOIN date_dim d3 ON ws3.ws_sold_date_sk = d3.d_date_sk
FULL OUTER JOIN (
    SELECT sr.sr_customer_sk,
           sr.sr_return_amt,
           d4.d_year
    FROM store_returns sr
    JOIN date_dim d4 ON sr.sr_returned_date_sk = d4.d_date_sk
    WHERE d4.d_year = 2001
) sr_full
ON sr_full.sr_customer_sk = ws3.ws_bill_customer_sk
WHERE d3.d_year = 2001
  AND sr_full.sr_customer_sk IS NOT NULL
ORDER BY date_sk DESC
LIMIT 100
