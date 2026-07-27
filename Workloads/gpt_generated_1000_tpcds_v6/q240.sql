WITH bill_sales AS (
   SELECT
       c.c_customer_id,
       CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
       regexp_extract(c.c_email_address, '@([^@]+)$', 1) AS email_domain,
       substring(c.c_last_name, 1, 3) AS last_name_prefix,
       SUM(cs.cs_net_paid) AS total_amount,
       SUM(cs.cs_quantity) AS total_quantity
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE regexp_like(c.c_email_address, '@example\\.com$')
     AND c.c_first_name LIKE 'J%'
     AND ib.ib_upper_bound BETWEEN 50000 AND 100000
     AND cs.cs_net_paid > (
         SELECT avg(cs2.cs_net_paid)
         FROM catalog_sales cs2
         JOIN customer c2 ON cs2.cs_bill_customer_sk = c2.c_customer_sk
         JOIN household_demographics hd2 ON c2.c_current_hdemo_sk = hd2.hd_demo_sk
         JOIN income_band ib2 ON hd2.hd_income_band_sk = ib2.ib_income_band_sk
         WHERE ib2.ib_upper_bound BETWEEN 50000 AND 100000
     )
   GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, c.c_email_address
),
ship_sales AS (
   SELECT
       c.c_customer_id,
       CONCAT(c.c_first_name, ' ', c.c_last_name) AS full_name,
       regexp_extract(c.c_email_address, '@([^@]+)$', 1) AS email_domain,
       substring(c.c_last_name, 1, 3) AS last_name_prefix,
       SUM(cs.cs_net_paid) AS total_amount,
       SUM(cs.cs_quantity) AS total_quantity
   FROM catalog_sales cs
   JOIN customer c ON cs.cs_ship_customer_sk = c.c_customer_sk
   JOIN household_demographics hd ON c.c_current_hdemo_sk = hd.hd_demo_sk
   JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
   WHERE cs.cs_quantity > 5
     AND EXISTS (
         SELECT 1
         FROM catalog_sales cs3
         WHERE cs3.cs_bill_customer_sk = c.c_customer_sk
           AND cs3.cs_quantity > 10
           AND cs3.cs_net_paid > 1000
     )
     AND ib.ib_lower_bound >= 20000
   GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name, c.c_email_address
   HAVING SUM(cs.cs_quantity) > 100
)
SELECT *
FROM (
   SELECT * FROM bill_sales
   UNION ALL
   SELECT * FROM ship_sales
) AS combined
ORDER BY total_amount DESC
LIMIT 100
