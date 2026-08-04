WITH
  promo_keys AS (
    SELECT p_promo_sk
    FROM promotion
    WHERE p_discount_active = 'Y'
  ),
  sales_filtered AS (
    SELECT ss.*
    FROM store_sales ss
    WHERE ss.ss_promo_sk IN (SELECT p_promo_sk FROM promo_keys)
  )
SELECT
  COALESCE(c.c_customer_sk, hd.hd_demo_sk) AS entity_id,
  le.domain,
  hd.hd_buy_potential,
  SUM(ss.ss_net_paid) AS total_net_paid,
  COUNT(*) AS sales_count,
  MAX(t.t_hour) AS latest_sale_hour,
  MAX(CAST(le.email_number AS integer)) AS max_email_number
FROM
  customer c
  FULL OUTER JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN sales_filtered ss
    ON c.c_customer_sk = ss.ss_customer_sk
  LEFT JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  CROSS JOIN LATERAL (
    SELECT
      REGEXP_EXTRACT(c.c_email_address, '@([^.]*)') AS domain,
      REGEXP_EXTRACT(c.c_email_address, '[0-9]+') AS email_number
  ) le
WHERE
  c.c_customer_sk IN (
    SELECT ss_customer_sk FROM store_sales
    EXCEPT
    SELECT c_customer_sk FROM customer WHERE c_preferred_cust_flag = 'Y'
  )
  AND c.c_email_address LIKE '%@%.com'
  AND REGEXP_LIKE(c.c_email_address, '^[A-Z][a-z]+\.[A-Z][a-z]+@')
GROUP BY
  COALESCE(c.c_customer_sk, hd.hd_demo_sk),
  le.domain,
  hd.hd_buy_potential
ORDER BY
  total_net_paid DESC
LIMIT 100
