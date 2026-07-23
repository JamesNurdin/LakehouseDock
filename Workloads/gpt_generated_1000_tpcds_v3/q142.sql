WITH sales_agg AS (
  SELECT
    ss.ss_store_sk,
    ss.ss_promo_sk,
    d.d_year,
    t.t_shift,
    sum(ss.ss_ext_sales_price) AS total_sales,
    sum(ss.ss_net_profit) AS total_profit,
    count(*) AS transaction_count
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
  WHERE regexp_like(p.p_promo_name, '(?i)discount')
    AND p.p_cost > (
      SELECT avg(p2.p_cost)
      FROM promotion p2
      WHERE regexp_like(p2.p_promo_name, '(?i)discount')
    )
  GROUP BY ss.ss_store_sk, ss.ss_promo_sk, d.d_year, t.t_shift
  HAVING sum(ss.ss_ext_sales_price) > 10000
)
SELECT
  s.s_store_id,
  s.s_store_name,
  substring(s.s_store_name, 1, 10) AS store_name_prefix,
  concat(s.s_city, ', ', s.s_state) AS store_location,
  a.d_year,
  a.t_shift,
  a.total_sales,
  a.total_profit,
  a.transaction_count,
  regexp_extract(p.p_promo_name, '[0-9]+', 0) AS promo_code,
  (
    SELECT max(p2.p_cost)
    FROM promotion p2
    WHERE p2.p_promo_sk = a.ss_promo_sk
  ) AS max_promo_cost
FROM sales_agg a
JOIN store s ON a.ss_store_sk = s.s_store_sk
JOIN promotion p ON a.ss_promo_sk = p.p_promo_sk
WHERE s.s_city LIKE 'San%'
ORDER BY a.total_sales DESC
LIMIT 100
