WITH catalog_year AS (
  SELECT
    cp.cp_catalog_page_sk,
    cp.cp_description,
    d.d_year AS year_val,
    regexp_extract(cp.cp_description, '(\\w+)', 1) AS first_word,
    concat('Y', CAST(d.d_year AS varchar)) AS year_label
  FROM catalog_page cp
  JOIN date_dim d
    ON cp.cp_start_date_sk = d.d_date_sk
  WHERE regexp_like(cp.cp_description, '(?i)care')
    AND cp.cp_description LIKE '%fields%'
),
promo_year AS (
  SELECT
    p.p_promo_sk,
    d.d_year AS promo_year,
    p.p_channel_tv
  FROM promotion p
  JOIN date_dim d
    ON p.p_start_date_sk = d.d_date_sk
  WHERE p.p_channel_tv = 'N'
)
SELECT
  c.year_label,
  c.year_val,
  COUNT(DISTINCT c.cp_catalog_page_sk) AS catalog_page_cnt,
  COUNT(DISTINCT pr.p_promo_sk) AS promotion_cnt,
  MIN(c.first_word) AS sample_first_word
FROM catalog_year c
LEFT JOIN promo_year pr
  ON c.year_val = pr.promo_year
GROUP BY
  c.year_label,
  c.year_val
ORDER BY c.year_val DESC, catalog_page_cnt DESC
LIMIT 100
