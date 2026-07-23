WITH filtered_promos AS (
  SELECT
    p.p_promo_sk,
    p.p_promo_name,
    p.p_channel_catalog,
    regexp_extract(p.p_promo_name, '(\\w+)', 1) AS promo_first_word
  FROM tpcds.promotion p
  WHERE p.p_channel_catalog = 'Y'
    AND regexp_like(p.p_promo_name, '(?i)(Discount|Clearance)')
)
SELECT
  s.s_store_id,
  s.s_store_name,
  substring(s.s_zip, 1, 3) AS zip_prefix,
  month(d.d_date) AS month,
  fp.promo_first_word,
  concat(s.s_store_name, ' - ', fp.p_promo_name) AS store_promo,
  sum(cs.cs_net_profit) AS total_profit,
  sum(cs.cs_ext_sales_price) AS total_sales
FROM tpcds.catalog_sales cs
JOIN tpcds.date_dim d
  ON cs.cs_ship_date_sk = d.d_date_sk
JOIN filtered_promos fp
  ON cs.cs_promo_sk = fp.p_promo_sk
JOIN tpcds.store s
  ON s.s_closed_date_sk = d.d_date_sk
WHERE s.s_city LIKE 'San%'
GROUP BY
  s.s_store_id,
  s.s_store_name,
  substring(s.s_zip, 1, 3),
  month(d.d_date),
  fp.promo_first_word,
  concat(s.s_store_name, ' - ', fp.p_promo_name)
ORDER BY total_profit DESC
LIMIT 100
