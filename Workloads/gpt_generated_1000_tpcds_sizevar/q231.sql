WITH promo_intersect AS (
    SELECT p.p_promo_sk
    FROM promotion p
    WHERE regexp_like(p.p_promo_name, 'Sale')
    INTERSECT
    SELECT ss2.ss_promo_sk
    FROM store_sales ss2
    WHERE ss2.ss_ext_discount_amt > 100
)
SELECT
    c.c_customer_id,
    c.c_last_name,
    c.c_birth_country,
    SUM(ss.ss_net_paid) AS total_sales,
    SUM(wr.wr_return_amt) AS total_returns
FROM store_sales ss
JOIN customer c
  ON ss.ss_customer_sk = c.c_customer_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
LEFT JOIN web_returns wr
  ON wr.wr_returning_customer_sk = c.c_customer_sk
  AND wr.wr_returned_time_sk = t.t_time_sk
WHERE
    c.c_birth_country LIKE '%ISLAND%'
    AND regexp_extract(c.c_email_address, '^([^@]+)@') = 'john.doe'
    AND t.t_hour = 15
    AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ss.ss_promo_sk
          AND regexp_like(p.p_promo_name, '^Summer.*')
    )
    AND ss.ss_promo_sk IN (SELECT p_promo_sk FROM promo_intersect)
GROUP BY
    c.c_customer_id,
    c.c_last_name,
    c.c_birth_country
ORDER BY total_sales DESC
LIMIT 100
