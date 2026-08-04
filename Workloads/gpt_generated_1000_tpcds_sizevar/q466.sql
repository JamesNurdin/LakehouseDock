WITH sales_part AS (
  SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    p.p_promo_name,
    CASE WHEN regexp_like(p.p_promo_name, '(?i)discount') THEN 'Discount' ELSE 'Other' END AS promo_category,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2001
    AND s.s_store_name LIKE '%Market%'
    AND regexp_like(p.p_channel_catalog, '^N$')
    AND regexp_like(p.p_promo_name, '(?i)discount')
  GROUP BY
    s.s_store_id,
    s.s_store_name,
    CONCAT(s.s_city, ', ', s.s_state),
    p.p_promo_name,
    CASE WHEN regexp_like(p.p_promo_name, '(?i)discount') THEN 'Discount' ELSE 'Other' END
),
sales_part2 AS (
  SELECT
    s.s_store_id AS store_id,
    s.s_store_name AS store_name,
    CONCAT(s.s_city, ', ', s.s_state) AS store_location,
    p.p_promo_name,
    CASE WHEN regexp_like(p.p_promo_name, '(?i)clearance') THEN 'Clearance' ELSE 'Other' END AS promo_category,
    SUM(ss.ss_net_paid) AS total_net_paid,
    COUNT(*) AS sales_cnt
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE d.d_year = 2001
    AND s.s_store_name LIKE '%Market%'
    AND regexp_like(p.p_channel_email, '^Y$')
    AND regexp_like(p.p_promo_name, '(?i)clearance')
  GROUP BY
    s.s_store_id,
    s.s_store_name,
    CONCAT(s.s_city, ', ', s.s_state),
    p.p_promo_name,
    CASE WHEN regexp_like(p.p_promo_name, '(?i)clearance') THEN 'Clearance' ELSE 'Other' END
),
union_sales AS (
  SELECT * FROM sales_part
  UNION
  SELECT * FROM sales_part2
)
SELECT
  ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS rn,
  store_id,
  store_name,
  store_location,
  p_promo_name,
  promo_category,
  total_net_paid,
  sales_cnt
FROM union_sales
ORDER BY rn
LIMIT 100
