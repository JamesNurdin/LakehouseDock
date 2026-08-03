/*
Goal: Identify customers who bought items in 2001 from streets whose name contains "Road" or "Street" and who also had a return exceeding $100 in the same year. For those customers, calculate total net profit, count of sales, profit category, first letter of the city, and each digit of the street number. The result is grouped, filtered by a HAVING clause, ordered by profit, and limited to the top 50 rows.
*/
WITH
  sales_filtered AS (
    SELECT
      ss.ss_customer_sk,
      ss.ss_sold_date_sk,
      ca.ca_city,
      ca.ca_street_name,
      ca.ca_street_number,
      cd.cd_gender,
      d.d_year,
      ss.ss_net_profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND (ca.ca_street_name LIKE '%Road%' OR ca.ca_street_name LIKE '%Street%')
      AND regexp_like(cd.cd_gender, '^[MF]$')
  ),
  returns_filtered AS (
    SELECT
      sr.sr_customer_sk,
      sr.sr_returned_date_sk,
      ca.ca_city,
      cd.cd_gender,
      d.d_year
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND sr.sr_refunded_cash > 100
  ),
  intersect_customers AS (
    SELECT ss_customer_sk AS customer_sk FROM sales_filtered
    INTERSECT
    SELECT sr_customer_sk FROM returns_filtered
  )
SELECT
  ic.customer_sk,
  sf.d_year,
  sf.ca_city,
  sf.cd_gender,
  sum(sf.ss_net_profit) AS total_profit,
  count(*) AS sales_cnt,
  CASE WHEN sum(sf.ss_net_profit) > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
  l.first_letter_city,
  t.digit AS street_number_digit
FROM intersect_customers ic
JOIN sales_filtered sf ON ic.customer_sk = sf.ss_customer_sk
CROSS JOIN LATERAL (
  SELECT substring(sf.ca_city, 1, 1) AS first_letter_city
) l
CROSS JOIN UNNEST(regexp_split(sf.ca_street_number, '')) AS t(digit)
GROUP BY
  ic.customer_sk,
  sf.d_year,
  sf.ca_city,
  sf.cd_gender,
  l.first_letter_city,
  t.digit
HAVING sum(sf.ss_net_profit) > 0
ORDER BY total_profit DESC
LIMIT 50
