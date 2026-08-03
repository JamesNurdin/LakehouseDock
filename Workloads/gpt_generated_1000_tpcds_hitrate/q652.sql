/*
  Goal: Identify the top‑3 web sales amounts per sold date for customers whose first name starts with a vowel, whose email belongs to the example.com (or .net) domain, and whose last name ends with "son" and email ends with @test.com.  The analysis is limited to sales of promotions whose name contains "Clearance" and includes a year between 2020‑2023.  The query demonstrates regexp_like, regexp_extract, LIKE, string concatenation, a TABLESAMPLE, an INTERSECT of two customer sets, a CTE hierarchy, and a ranking window function to keep only the top‑3 rows per date.
*/
WITH filtered_customers AS (
    SELECT c.c_customer_sk,
           concat(c.c_first_name, ' ', c.c_last_name) AS full_name,
           c.c_email_address
    FROM customer c
    WHERE regexp_like(c.c_first_name, '^[AEIOU].*')
      AND regexp_like(c.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.(com|net)$')
),
other_filtered AS (
    SELECT c.c_customer_sk
    FROM customer c
    WHERE regexp_like(c.c_last_name, 'son$')
      AND c.c_email_address LIKE '%@test.com'
),
intersected_customers AS (
    SELECT c_customer_sk FROM filtered_customers
    INTERSECT
    SELECT c_customer_sk FROM other_filtered
),
promo_filtered AS (
    SELECT p.p_promo_sk,
           p.p_promo_name,
           regexp_extract(p.p_promo_name, '(\\d{4})', 1) AS promo_year
    FROM promotion p
    WHERE p.p_promo_name LIKE '%Clearance%'
      AND regexp_like(p.p_promo_name, '.*202[0-3].*')
),
sales_sample AS (
    SELECT ws.ws_sold_date_sk,
           ws.ws_bill_customer_sk,
           ws.ws_promo_sk,
           sum(ws.ws_ext_sales_price) AS total_sales
    FROM web_sales ws TABLESAMPLE BERNOULLI (10)
    GROUP BY ws.ws_sold_date_sk, ws.ws_bill_customer_sk, ws.ws_promo_sk
),
customer_sales AS (
    SELECT fc.c_customer_sk,
           fc.full_name,
           ss.ws_sold_date_sk,
           ss.total_sales,
           p.p_promo_name,
           row_number() OVER (PARTITION BY ss.ws_sold_date_sk ORDER BY ss.total_sales DESC) AS rnk
    FROM intersected_customers ic
    JOIN filtered_customers fc ON ic.c_customer_sk = fc.c_customer_sk
    JOIN sales_sample ss ON fc.c_customer_sk = ss.ws_bill_customer_sk
    JOIN promo_filtered p ON ss.ws_promo_sk = p.p_promo_sk
)
SELECT cs.ws_sold_date_sk,
       cs.c_customer_sk,
       cs.full_name,
       cs.p_promo_name,
       cs.total_sales
FROM customer_sales cs
WHERE cs.rnk <= 3
ORDER BY cs.ws_sold_date_sk, cs.total_sales DESC
