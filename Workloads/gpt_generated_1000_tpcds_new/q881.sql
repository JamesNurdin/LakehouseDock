WITH full_join AS (
   SELECT
       c.c_customer_id,
       c.c_first_name,
       c.c_last_name,
       c.c_salutation,
       c.c_first_shipto_date_sk,
       c.c_first_sales_date_sk,
       d.d_date,
       d.d_year,
       d.d_qoy
   FROM customer c
   FULL OUTER JOIN date_dim d
       ON c.c_first_shipto_date_sk = d.d_date_sk
),

joined_with_lateral AS (
   SELECT
       fj.c_customer_id,
       fj.c_first_name,
       fj.c_last_name,
       fj.c_salutation,
       fj.d_year,
       fj.d_qoy,
       fj.d_date,
       (SELECT COUNT(*) FROM customer c2 WHERE c2.c_last_name = fj.c_last_name) AS last_name_freq,
       ROW_NUMBER() OVER (PARTITION BY fj.c_salutation ORDER BY fj.d_year) AS salutation_seq,
       lt.max_year_for_qoy
   FROM full_join fj
   CROSS JOIN LATERAL (
       SELECT MAX(d2.d_year) AS max_year_for_qoy
       FROM date_dim d2
       WHERE d2.d_qoy = fj.d_qoy
   ) AS lt
   WHERE fj.c_salutation IN ('Mrs.', 'Mr.', 'Ms.')
     AND EXISTS (
         SELECT 1
         FROM date_dim d3
         WHERE d3.d_year = fj.d_year
           AND d3.d_qoy = 2
     )
)

SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    c_salutation,
    d_year,
    d_qoy,
    last_name_freq,
    salutation_seq,
    max_year_for_qoy
FROM joined_with_lateral
WHERE d_year = 1998
UNION
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    c_salutation,
    d_year,
    d_qoy,
    last_name_freq,
    salutation_seq,
    max_year_for_qoy
FROM joined_with_lateral
WHERE d_year = 1999
ORDER BY c_last_name, c_first_name
LIMIT 100
