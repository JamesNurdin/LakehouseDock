WITH filtered_customer AS (
        SELECT c_customer_sk,
               c_salutation,
               c_first_shipto_date_sk
        FROM   customer
        WHERE  c_salutation = 'Mr.'
          AND  c_birth_year = 1985
    ),
    filtered_promo AS (
        SELECT p_promo_sk,
               p_cost,
               p_start_date_sk
        FROM   promotion
        WHERE  p_discount_active = 'Y'
          AND  p_cost > 100
    )
SELECT
    s.s_state,
    w.web_class,
    d.d_year,
    c.c_salutation,
    COUNT(DISTINCT c.c_customer_sk)      AS num_customers,
    SUM(p.p_cost)                        AS total_promo_cost,
    AVG(p.p_cost)                        AS avg_promo_cost,
    MIN(s.s_floor_space)                 AS min_floor_space,
    MAX(s.s_floor_space)                 AS max_floor_space
FROM   date_dim d
JOIN   filtered_customer c ON c.c_first_shipto_date_sk = d.d_date_sk
JOIN   filtered_promo    p ON p.p_start_date_sk      = d.d_date_sk
JOIN   store             s ON s.s_closed_date_sk    = d.d_date_sk
JOIN   web_site          w ON w.web_open_date_sk    = d.d_date_sk
WHERE  d.d_year BETWEEN 2000 AND 2005
  AND  s.s_state = 'CA'
  AND  w.web_class = 'Retail'
  AND  d.d_month_seq = 12
GROUP BY
    s.s_state,
    w.web_class,
    d.d_year,
    c.c_salutation
ORDER BY
    total_promo_cost DESC
LIMIT 100
