WITH returns_high_credit AS (
   SELECT
      c.c_customer_id AS c_customer_id,
      c.c_first_name AS c_first_name,
      c.c_last_name AS c_last_name,
      CASE WHEN c.c_salutation = 'Mr.' THEN 'Male' ELSE 'Other' END AS gender_est,
      SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
      COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   WHERE sr.sr_store_credit > 100
   GROUP BY c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            CASE WHEN c.c_salutation = 'Mr.' THEN 'Male' ELSE 'Other' END
),
returns_high_ship AS (
   SELECT
      c.c_customer_id AS c_customer_id,
      c.c_first_name AS c_first_name,
      c.c_last_name AS c_last_name,
      CASE WHEN c.c_salutation = 'Mr.' THEN 'Male' ELSE 'Other' END AS gender_est,
      SUM(sr.sr_return_amt_inc_tax) AS total_return_inc_tax,
      COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
   FROM store_returns sr
   JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
   WHERE sr.sr_return_ship_cost > 200
   GROUP BY c.c_customer_id,
            c.c_first_name,
            c.c_last_name,
            CASE WHEN c.c_salutation = 'Mr.' THEN 'Male' ELSE 'Other' END
)
SELECT DISTINCT
   customer_id,
   first_name,
   last_name,
   gender_est,
   total_return_inc_tax,
   distinct_tickets
FROM (
   SELECT
      c_customer_id   AS customer_id,
      c_first_name    AS first_name,
      c_last_name     AS last_name,
      gender_est,
      total_return_inc_tax,
      distinct_tickets
   FROM returns_high_credit
   UNION ALL
   SELECT
      c_customer_id,
      c_first_name,
      c_last_name,
      gender_est,
      total_return_inc_tax,
      distinct_tickets
   FROM returns_high_ship
) AS combined
ORDER BY total_return_inc_tax DESC
LIMIT 100
