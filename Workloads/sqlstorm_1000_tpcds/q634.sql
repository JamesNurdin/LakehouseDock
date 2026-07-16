WITH
  daily_sales AS (
    SELECT
      d.d_date,
      i.i_item_sk,
      i.i_product_name,
      i.i_item_desc,
      i.i_brand,
      i.i_category,
      i.i_class,
      i.i_color,
      cs.cs_net_profit,
      cs.cs_quantity,
      cs.cs_call_center_sk,
      cs.cs_promo_sk
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
  ),
  item_normalized AS (
    SELECT
      ds.*,
      lower(regexp_replace(i_product_name, '[^a-zA-Z0-9]', '')) AS product_name_alnum,
      regexp_replace(i_item_desc, '\\s+', ' ') AS desc_single_space,
      substr(i_item_desc, 1, 30) AS item_desc_prefix,
      substr(i_item_desc, strpos(i_item_desc, ' ') + 1) AS item_desc_after_first_space
    FROM daily_sales ds
  ),
  call_center_info AS (
    SELECT
      cc.cc_call_center_sk,
      trim(cc.cc_name) AS cc_name_trim,
      regexp_replace(cc.cc_hours, '\\s+', '') AS cc_hours_nospace,
      upper(cc.cc_manager) AS cc_manager_upper,
      concat_ws('_', replace(cc.cc_city, ' ', ''), cc.cc_state) AS cc_city_state_key
    FROM call_center cc
  ),
  promo_info AS (
    SELECT
      p.p_promo_sk,
      lower(p.p_promo_name) AS promo_name_lower,
      regexp_replace(p.p_promo_name, '\\s+', '-') AS promo_name_dash,
      p.p_channel_email,
      p.p_channel_catalog
    FROM promotion p
  ),
  agg_sales AS (
    SELECT
      ds.d_date,
      ds.i_item_sk,
      ds.i_product_name,
      ds.product_name_alnum,
      sum(ds.cs_net_profit) AS total_net_profit,
      sum(ds.cs_quantity) AS total_quantity,
      array_agg(DISTINCT cc.cc_city_state_key) AS city_state_keys,
      max(cc.cc_manager_upper) AS manager_upper,
      max(promo.promo_name_dash) AS promo_name_dash
    FROM item_normalized ds
    LEFT JOIN call_center_info cc ON ds.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN promo_info promo ON ds.cs_promo_sk = promo.p_promo_sk
    GROUP BY ds.d_date, ds.i_item_sk, ds.i_product_name, ds.product_name_alnum
  ),
  final_strings AS (
    SELECT
      d_date,
      i_item_sk,
      i_product_name,
      concat(
        'DATE:', CAST(d_date AS varchar), '|',
        'ITEM:', product_name_alnum, '|',
        'PROFIT:', CAST(total_net_profit AS varchar), '|',
        'QTY:', CAST(total_quantity AS varchar), '|',
        'MANAGER:', coalesce(manager_upper, 'UNKNOWN'), '|',
        'CITIES:', array_join(city_state_keys, ',')
      ) AS detailed_key,
      CASE
        WHEN total_net_profit > 10000 THEN 'HIGH'
        WHEN total_net_profit > 1000 THEN 'MEDIUM'
        ELSE 'LOW'
      END AS profit_bucket
    FROM agg_sales
  )
SELECT
  detailed_key,
  profit_bucket,
  count(*) AS occurrence
FROM final_strings
GROUP BY detailed_key, profit_bucket
ORDER BY occurrence DESC
LIMIT 20
