WITH filtered_sales AS (
  SELECT
    cs.cs_sold_date_sk,
    cs.cs_bill_customer_sk,
    cs.cs_promo_sk,
    cs.cs_net_paid_inc_tax,
    cs.cs_quantity,
    c.c_email_address
  FROM catalog_sales cs
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  WHERE regexp_like(c.c_email_address, '@.+\\.com$')
),
promo_lateral AS (
  SELECT
    fs.cs_sold_date_sk,
    fs.cs_bill_customer_sk,
    fs.cs_promo_sk,
    fs.cs_net_paid_inc_tax,
    d.d_year,
    p.p_promo_id,
    p.p_promo_name,
    pl.first_word
  FROM filtered_sales fs
  JOIN date_dim d
    ON fs.cs_sold_date_sk = d.d_date_sk
  JOIN promotion p
    ON fs.cs_promo_sk = p.p_promo_sk
  JOIN LATERAL (
    SELECT regexp_extract(p.p_promo_name, '^(\\w+)', 1) AS first_word
  ) pl ON true
  WHERE p.p_promo_name LIKE '%Sale%'
    AND regexp_like(p.p_promo_name, 'Sale')
)
SELECT
  d_year,
  p_promo_id,
  first_word,
  CONCAT(first_word, '_', CAST(d_year AS varchar)) AS promo_year_label,
  SUM(cs_net_paid_inc_tax) AS total_net_paid,
  COUNT(DISTINCT cs_bill_customer_sk) AS distinct_customers,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY SUM(cs_net_paid_inc_tax) DESC) AS row_num
FROM promo_lateral
GROUP BY d_year, p_promo_id, first_word
ORDER BY d_year DESC, total_net_paid DESC
LIMIT 100
