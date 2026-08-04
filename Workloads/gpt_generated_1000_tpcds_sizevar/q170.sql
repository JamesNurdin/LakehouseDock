WITH
  agg AS (
    SELECT
      promo_id,
      total_sales,
      email_prefix,
      CONCAT(email_prefix, '_', promo_id) AS promo_key
    FROM (
      SELECT
        p.p_promo_id AS promo_id,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUBSTRING(c.c_email_address, 1, POSITION('@' IN c.c_email_address) - 1) AS email_prefix
      FROM catalog_sales cs
      JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
      JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
      WHERE regexp_like(c.c_email_address, '^[A-Za-z]+\\.[A-Za-z]+@.*\\.org$')
        AND c.c_email_address LIKE '%@%.org'
      GROUP BY p.p_promo_id,
               SUBSTRING(c.c_email_address, 1, POSITION('@' IN c.c_email_address) - 1)
      UNION
      SELECT
        p.p_promo_id AS promo_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUBSTRING(c.c_email_address, 1, POSITION('@' IN c.c_email_address) - 1) AS email_prefix
      FROM store_sales ss
      JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
      JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
      WHERE regexp_extract(c.c_email_address, '@([^\\.]+)\\.org$', 1) IS NOT NULL
        AND c.c_email_address LIKE '%@%.org'
      GROUP BY p.p_promo_id,
               SUBSTRING(c.c_email_address, 1, POSITION('@' IN c.c_email_address) - 1)
    ) u
  ),
  bad_promos AS (
    SELECT p.p_promo_id AS promo_id
    FROM catalog_returns cr
    JOIN catalog_sales cs ON cr.cr_order_number = cs.cs_order_number
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cr.cr_net_loss > 1000
  ),
  agg_bad AS (
    SELECT a.promo_id, a.total_sales, a.email_prefix, a.promo_key
    FROM agg a
    JOIN bad_promos b ON a.promo_id = b.promo_id
  )
SELECT a.promo_id,
       a.total_sales,
       a.email_prefix,
       a.promo_key
FROM agg a
EXCEPT
SELECT b.promo_id,
       b.total_sales,
       b.email_prefix,
       b.promo_key
FROM agg_bad b
ORDER BY total_sales DESC
LIMIT 100
