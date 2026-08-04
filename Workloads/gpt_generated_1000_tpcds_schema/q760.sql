WITH sales_agg AS (
  SELECT
    ss_customer_sk,
    ss_promo_sk,
    ss_sold_time_sk,
    ss_cdemo_sk,
    SUM(ss_ext_sales_price) AS total_sales,
    COUNT(*) AS sales_cnt,
    AVG(ss_ext_discount_amt) AS avg_discount
  FROM store_sales
  WHERE ss_ext_sales_price > 1000
    AND ss_quantity >= 2
    AND ss_ext_discount_amt > 0
  GROUP BY ss_customer_sk, ss_promo_sk, ss_sold_time_sk, ss_cdemo_sk
),
intersect_keys AS (
  SELECT c_customer_sk FROM customer WHERE c_birth_year = 1965
  INTERSECT
  SELECT ss_customer_sk FROM store_sales WHERE ss_ext_sales_price > 2000
)
SELECT
  c.c_customer_id,
  p.p_promo_name,
  t.t_sub_shift,
  cd.cd_credit_rating,
  agg.total_sales,
  agg.sales_cnt,
  agg.avg_discount
FROM sales_agg agg
JOIN customer c ON agg.ss_customer_sk = c.c_customer_sk
JOIN promotion p ON agg.ss_promo_sk = p.p_promo_sk
JOIN time_dim t ON agg.ss_sold_time_sk = t.t_time_sk
JOIN customer_demographics cd ON agg.ss_cdemo_sk = cd.cd_demo_sk
JOIN intersect_keys ik ON c.c_customer_sk = ik.c_customer_sk
WHERE p.p_channel_email = 'N'
  AND p.p_purpose = 'Unknown'
  AND cd.cd_credit_rating = 'Low Risk'
  AND t.t_sub_shift = 'evening'
  AND c.c_customer_sk NOT IN (SELECT c_customer_sk FROM customer WHERE c_preferred_cust_flag = 'Y')
  AND EXISTS (
    SELECT 1 FROM promotion p2 WHERE p2.p_promo_id = p.p_promo_id AND p2.p_channel_tv = 'Y'
  )
GROUP BY
  c.c_customer_id,
  p.p_promo_name,
  t.t_sub_shift,
  cd.cd_credit_rating,
  agg.total_sales,
  agg.sales_cnt,
  agg.avg_discount
ORDER BY agg.total_sales DESC
LIMIT 100
