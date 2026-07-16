WITH sales AS (
  SELECT
    d.d_year,
    i.i_category,
    i.i_item_desc,
    ss.ss_net_profit,
    ss.ss_ext_sales_price,
    ss.ss_ext_discount_amt,
    ss.ss_promo_sk
  FROM store_sales ss
  JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  WHERE d.d_year BETWEEN 1999 AND 2002
), exploded_words AS (
  SELECT
    s.d_year,
    s.i_category,
    s.i_item_desc,
    s.ss_net_profit,
    s.ss_ext_discount_amt,
    s.ss_promo_sk,
    trim(regexp_replace(word, '[^A-Za-z0-9]', '')) AS clean_word
  FROM sales s
  CROSS JOIN UNNEST(split(s.i_item_desc, '\\s+')) AS t(word)
  WHERE word <> ''
), promo_joined AS (
  SELECT
    e.*,
    p.p_promo_name
  FROM exploded_words e
  LEFT JOIN promotion p ON e.ss_promo_sk = p.p_promo_sk
)
SELECT
  pj.d_year,
  pj.i_category,
  count(*) AS total_sales_records,
  sum(pj.ss_net_profit) AS total_net_profit,
  avg(length(regexp_replace(lower(pj.i_item_desc), '\\s+', ' '))) AS avg_clean_desc_len,
  avg(length(substring(pj.i_item_desc, 1, 30))) AS avg_first30_len,
  count(DISTINCT lower(pj.clean_word)) AS distinct_words,
  sum(CASE WHEN regexp_like(lower(pj.i_item_desc), 'steel') THEN 1 ELSE 0 END) AS steel_desc_count,
  sum(CASE WHEN pj.p_promo_name IS NOT NULL AND regexp_like(lower(pj.p_promo_name), 'discount|sale') THEN pj.ss_ext_discount_amt ELSE 0 END) AS discount_amount,
  max(regexp_extract(pj.p_promo_name, '(\\d+)')) AS max_promo_number,
  avg(length(replace(pj.i_item_desc, ' ', '_'))) AS avg_underscored_len
FROM promo_joined pj
GROUP BY pj.d_year, pj.i_category
ORDER BY pj.d_year, pj.i_category
