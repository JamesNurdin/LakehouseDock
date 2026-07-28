WITH sales_filtered AS (
  SELECT
    d.d_year,
    p.p_promo_name,
    cs.cs_net_profit,
    i.i_item_desc
  FROM catalog_sales cs
  JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  JOIN item i ON cs.cs_item_sk = i.i_item_sk
  WHERE p.p_channel_dmail = 'Y'
    AND p.p_promo_name LIKE '%Clearance%'
    AND regexp_like(i.i_item_desc, '\\bModel [A-Z][0-9]{3}\\b')
)
SELECT
  d_year,
  p_promo_name,
  sum(cs_net_profit) AS total_net_profit,
  count(*) AS transaction_cnt,
  concat(p_promo_name, ' ', cast(d_year AS varchar)) AS promo_year_label,
  array_agg(DISTINCT regexp_extract(i_item_desc, 'Model ([A-Z][0-9]{3})', 1)) AS model_codes
FROM sales_filtered
GROUP BY d_year, p_promo_name
HAVING sum(cs_net_profit) > 10000
ORDER BY total_net_profit DESC
LIMIT 100
