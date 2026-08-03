WITH cs_sample AS (
    SELECT *
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
)
SELECT
    i.i_category,
    hd.hd_income_band_sk,
    c.c_birth_month,
    p.p_promo_name,
    SUM(cs.cs_net_paid) AS total_sales,
    SUM(cr.cr_return_amount) AS total_returns,
    AVG(ss.ss_net_paid) AS avg_store_sales,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    MIN(cs.cs_sold_date_sk) AS first_sold_date_sk,
    MAX(cs.cs_sold_date_sk) AS last_sold_date_sk
FROM cs_sample cs
JOIN customer c
      ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN household_demographics hd
      ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
JOIN catalog_returns cr
      ON cr.cr_item_sk = cs.cs_item_sk
     AND cr.cr_order_number = cs.cs_order_number
JOIN store_sales ss
      ON ss.ss_item_sk = i.i_item_sk
     AND ss.ss_customer_sk = c.c_customer_sk
     AND ss.ss_hdemo_sk = hd.hd_demo_sk
     AND ss.ss_promo_sk = p.p_promo_sk
JOIN web_page wp
      ON wp.wp_customer_sk = c.c_customer_sk
WHERE
      c.c_birth_year = 1975
  AND i.i_class_id IN (1, 2, 3)
  AND p.p_discount_active = 'Y'
  AND wp.wp_char_count > 500
  AND cr.cr_return_quantity > 1
GROUP BY
    i.i_category,
    hd.hd_income_band_sk,
    c.c_birth_month,
    p.p_promo_name
HAVING
    SUM(cs.cs_net_paid) > 10000
    AND COUNT(cr.cr_return_quantity) > 5
ORDER BY total_sales DESC
LIMIT 100
