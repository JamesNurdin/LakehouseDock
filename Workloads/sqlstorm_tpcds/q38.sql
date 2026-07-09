WITH base AS (
  SELECT 
    s.s_store_name,
    s.s_city,
    d.d_day_name,
    c.c_email_address,
    i.i_product_name,
    i.i_item_desc,
    p.p_promo_name,
    ss.ss_net_paid
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE ss.ss_quantity > 0
),
agg AS (
  SELECT
    s_store_name,
    s_city,
    d_day_name,
    COUNT(*) AS sales_cnt,
    SUM(ss_net_paid) AS total_net_paid,
    array_join(
      array_agg(DISTINCT lower(trim(split_part(c_email_address, '@', 2)))),
      ','
    ) AS email_domains,
    MAX(length(regexp_replace(concat(i_product_name, ' ', i_item_desc), '[^A-Za-z0-9 ]', ' '))) AS max_cleaned_desc_len,
    COUNT(DISTINCT substring(i_product_name, 1, 3)) AS distinct_prefix_cnt,
    COUNT(DISTINCT CASE WHEN p_promo_name IS NOT NULL THEN regexp_extract(p_promo_name, '([^ -]+)') END) AS promo_prefix_cnt,
    substring(array_join(array_agg(i_product_name), '|'), 1, 1000) AS product_names_pipe
  FROM base
  GROUP BY s_store_name, s_city, d_day_name
  HAVING COUNT(*) > 100
)
SELECT
  s_store_name,
  s_city,
  d_day_name,
  sales_cnt,
  total_net_paid,
  email_domains,
  max_cleaned_desc_len,
  distinct_prefix_cnt,
  promo_prefix_cnt,
  product_names_pipe,
  RANK() OVER (ORDER BY total_net_paid DESC) AS store_sales_rank
FROM agg
ORDER BY total_net_paid DESC
LIMIT 50
