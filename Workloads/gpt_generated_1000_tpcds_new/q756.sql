WITH
  sampled_pages AS (
    SELECT
      wp_web_page_sk,
      wp_url,
      wp_char_count,
      wp_type,
      wp_creation_date_sk
    FROM web_page TABLESAMPLE BERNOULLI (10)
    WHERE wp_url IS NOT NULL
  ),
  sampled_returns AS (
    SELECT
      wr_web_page_sk,
      wr_returned_date_sk,
      wr_return_amt_inc_tax,
      wr_return_quantity
    FROM web_returns TABLESAMPLE BERNOULLI (5)
  ),
  filtered_pages AS (
    SELECT
      sp.wp_web_page_sk,
      sp.wp_url,
      sp.wp_char_count,
      sp.wp_type,
      sp.wp_creation_date_sk,
      ud.domain
    FROM sampled_pages sp
    JOIN LATERAL (
      SELECT regexp_extract(sp.wp_url, 'https?://([^/]+)/', 1) AS domain
    ) ud ON true
    WHERE sp.wp_char_count > 3000
      AND sp.wp_url LIKE '%example.com%'
      AND regexp_like(sp.wp_url, 'blog')
  ),
  intersect_pages AS (
    SELECT wp_web_page_sk FROM filtered_pages
    INTERSECT
    SELECT wp_web_page_sk FROM sampled_pages WHERE wp_type = 'home'
  )
SELECT
  COALESCE(fp.wp_web_page_sk, fr.wr_web_page_sk) AS web_page_sk,
  d.d_year,
  COUNT(DISTINCT COALESCE(fp.wp_web_page_sk, fr.wr_web_page_sk)) AS page_count,
  SUM(fr.wr_return_amt_inc_tax) AS total_return_amount,
  MAX(fp.wp_char_count) AS max_char_count,
  MIN(fp.domain) FILTER (WHERE fp.domain IS NOT NULL) AS sample_domain
FROM (
  SELECT *
  FROM filtered_pages
  WHERE wp_web_page_sk IN (SELECT wp_web_page_sk FROM intersect_pages)
) fp
FULL OUTER JOIN (
  SELECT *
  FROM sampled_returns
  WHERE wr_web_page_sk IN (SELECT wp_web_page_sk FROM intersect_pages)
) fr
  ON fp.wp_web_page_sk = fr.wr_web_page_sk
LEFT JOIN date_dim d
  ON (CASE WHEN fp.wp_creation_date_sk IS NOT NULL THEN fp.wp_creation_date_sk ELSE fr.wr_returned_date_sk END) = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY
  COALESCE(fp.wp_web_page_sk, fr.wr_web_page_sk),
  d.d_year
ORDER BY
  total_return_amount DESC,
  d.d_year
