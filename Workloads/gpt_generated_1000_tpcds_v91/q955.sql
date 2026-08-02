WITH cs_agg AS (
   SELECT cs.cs_bill_customer_sk AS customer_sk,
          cs.cs_order_number AS order_number,
          cs.cs_sold_date_sk AS date_sk,
          array_agg(cs.cs_ext_sales_price) AS price_array
   FROM catalog_sales cs
   JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
   WHERE d.d_date >= DATE '2000-01-01' AND d.d_date <= DATE '2000-12-31'
   GROUP BY cs.cs_bill_customer_sk, cs.cs_order_number, cs.cs_sold_date_sk
),
cs_flat AS (
   SELECT a.customer_sk,
          a.order_number,
          a.date_sk,
          p AS price
   FROM cs_agg a
   CROSS JOIN UNNEST(a.price_array) AS t(p)
),
ss_agg AS (
   SELECT ss.ss_customer_sk AS customer_sk,
          ss.ss_ticket_number AS order_number,
          ss.ss_sold_date_sk AS date_sk,
          array_agg(ss.ss_ext_sales_price) AS price_array
   FROM store_sales ss
   JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
   WHERE d2.d_date >= DATE '2000-01-01' AND d2.d_date <= DATE '2000-12-31'
   GROUP BY ss.ss_customer_sk, ss.ss_ticket_number, ss.ss_sold_date_sk
),
ss_flat AS (
   SELECT s.customer_sk,
          s.order_number,
          s.date_sk,
          p AS price
   FROM ss_agg s
   CROSS JOIN UNNEST(s.price_array) AS t(p)
)
SELECT intersected.customer_sk,
       intersected.sales_price,
       intersected.date_sk
FROM (
    SELECT DISTINCT cs_flat.customer_sk,
                    cs_flat.price AS sales_price,
                    cs_flat.date_sk
    FROM cs_flat
    INTERSECT
    SELECT DISTINCT ss_flat.customer_sk,
                    ss_flat.price,
                    ss_flat.date_sk
    FROM ss_flat
) AS intersected
ORDER BY intersected.sales_price DESC
LIMIT 100
