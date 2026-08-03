WITH recent_store AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_division_name,
        s_city,
        s_state
    FROM store
    WHERE s_rec_end_date >= DATE '2000-01-01'
      AND regexp_like(s_store_name, '^A.*')
)

SELECT
    rs.s_division_name AS name,
    d.d_year AS year,
    COUNT(DISTINCT sr.sr_customer_sk) AS cnt,
    SUM(sr.sr_return_amt) AS amount,
    CONCAT(rs.s_city, ', ', rs.s_state) AS extra_text,
    regexp_extract(c.c_email_address, '(@.+)$') AS email_domain
FROM recent_store rs
JOIN store_returns sr
  ON rs.s_store_sk = sr.sr_store_sk
JOIN customer c
  ON sr.sr_customer_sk = c.c_customer_sk
JOIN date_dim d
  ON sr.sr_returned_date_sk = d.d_date_sk
WHERE d.d_year = (
        SELECT MAX(d_year)
        FROM date_dim
        WHERE d_current_month = 'Y'
      )
  AND c.c_email_address LIKE '%@example.com'
  AND substr(c.c_first_name, 1, 1) = 'J'
GROUP BY rs.s_division_name, d.d_year, rs.s_city, rs.s_state, c.c_email_address

UNION

SELECT
    c.c_last_name AS name,
    d.d_year AS year,
    COUNT(DISTINCT cr.cr_order_number) AS cnt,
    SUM(cr.cr_net_loss) AS amount,
    CASE WHEN regexp_like(c.c_email_address, '^.*@.*\\.org$') THEN 'Y' ELSE 'N' END AS extra_text,
    CAST(NULL AS varchar) AS email_domain
FROM catalog_returns cr
JOIN customer c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
WHERE c.c_birth_year = (
        SELECT MIN(c2.c_birth_year)
        FROM customer c2
        WHERE c2.c_preferred_cust_flag = 'Y'
      )
  AND EXISTS (
        SELECT 1
        FROM date_dim d2
        WHERE d2.d_year = d.d_year - 1
          AND d2.d_current_month = 'Y'
      )
GROUP BY c.c_last_name, d.d_year, c.c_email_address

LIMIT 100
