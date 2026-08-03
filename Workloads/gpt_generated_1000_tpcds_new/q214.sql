WITH cc_expand AS (
  SELECT
    cc.cc_call_center_sk,
    cc.cc_name,
    substring(cc.cc_name, 1, 10) AS name_prefix,
    word
  FROM call_center cc
  CROSS JOIN UNNEST(split(cc.cc_name, ' ')) AS t(word)
  WHERE cc.cc_name LIKE '%Hill%'
),

sales_base AS (
  SELECT
    td.t_hour AS hour,
    cs.cs_call_center_sk,
    cs.cs_net_paid,
    p.p_promo_name
  FROM catalog_sales cs
  JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  WHERE regexp_like(p.p_promo_name, '\\d{4}')
    AND p.p_channel_catalog = 'N'
),

sales_agg AS (
  SELECT
    sb.hour,
    sum(sb.cs_net_paid) AS total_sales,
    count(*) AS sales_cnt,
    count(DISTINCT cw.word) AS distinct_cc_word_cnt,
    max(cw.name_prefix) AS sample_name_prefix,
    max(sb.p_promo_name) AS promo_name
  FROM sales_base sb
  LEFT JOIN cc_expand cw ON sb.cs_call_center_sk = cw.cc_call_center_sk
  GROUP BY sb.hour
),

returns_agg AS (
  SELECT
    td.t_hour AS hour,
    sum(sr.sr_return_amt_inc_tax) AS total_returns,
    count(*) AS returns_cnt
  FROM store_returns sr
  JOIN time_dim td ON sr.sr_return_time_sk = td.t_time_sk
  GROUP BY td.t_hour
)
SELECT
  coalesce(sa.hour, ra.hour) AS hour,
  sa.total_sales,
  ra.total_returns,
  sa.sales_cnt,
  ra.returns_cnt,
  sa.distinct_cc_word_cnt,
  sa.sample_name_prefix,
  concat('Hour_', cast(coalesce(sa.hour, ra.hour) as varchar)) AS hour_label,
  regexp_extract(coalesce(sa.promo_name, ''), '(\\d{4})') AS promo_year_extracted
FROM sales_agg sa
FULL OUTER JOIN returns_agg ra ON sa.hour = ra.hour
ORDER BY hour DESC
LIMIT 100
