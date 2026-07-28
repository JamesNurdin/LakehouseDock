WITH sales_filtered AS (
  SELECT
    ss.ss_store_sk,
    ss.ss_net_profit,
    s.s_store_id,
    s.s_city,
    s.s_suite_number,
    s.s_store_name,
    d.d_year
  FROM store_sales ss
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  WHERE d.d_year = 2022
    AND regexp_like(s.s_suite_number, '[0-9]+')
    AND s.s_city LIKE '%York%'
    AND EXISTS (
      SELECT 1
      FROM promotion p
      WHERE p.p_promo_sk = ss.ss_promo_sk
        AND p.p_start_date_sk <= ss.ss_sold_date_sk
        AND p.p_end_date_sk >= ss.ss_sold_date_sk
    )
)
SELECT
  sf.s_store_id,
  sf.s_city,
  substring(sf.s_store_name, 1, 3) AS store_name_prefix,
  concat(sf.s_city, ' - ', sf.s_store_id) AS city_store,
  count(*) AS sales_count,
  sum(sf.ss_net_profit) AS total_net_profit,
  regexp_extract(sf.s_city, '(.*)York', 1) AS city_prefix_before_york
FROM sales_filtered sf
GROUP BY
  sf.s_store_id,
  sf.s_city,
  substring(sf.s_store_name, 1, 3),
  concat(sf.s_city, ' - ', sf.s_store_id),
  regexp_extract(sf.s_city, '(.*)York', 1)
ORDER BY total_net_profit DESC
LIMIT 100
