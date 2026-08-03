/*
Goal: Identify market classes of call centers that had returns in the year 2020, where the call center description matches a specific pattern and the related web pages have a dynamic type with several images. The query demonstrates string processing (REGEXP_LIKE, LIKE, SUBSTRING), uses a scalar sub‑query, an IN filter built from an INTERSECT of two sub‑queries, samples the store_returns table with TABLESAMPLE BERNOULLI, and aggregates the results.
*/
WITH
  call_center_regex AS (
    SELECT
      cc_call_center_sk,
      cc_mkt_class,
      cc_closed_date_sk
    FROM call_center
    WHERE regexp_like(cc_mkt_class, 'Associated')
  ),

  call_center_closed_2020 AS (
    SELECT cc.cc_call_center_sk
    FROM call_center cc
    JOIN date_dim d ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2020
  ),

  eligible_call_centers AS (
    SELECT cc_call_center_sk
    FROM call_center_regex
    INTERSECT
    SELECT cc_call_center_sk
    FROM call_center_closed_2020
  ),

  sampled_returns AS (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
    WHERE sr_return_amt_inc_tax > 100
  ),

  filtered_web_page AS (
    SELECT
      wp_web_page_sk,
      wp_type,
      wp_image_count,
      wp_creation_date_sk,
      wp_url
    FROM web_page
    WHERE wp_type LIKE 'dyn%'
      AND wp_image_count >= 3
      AND regexp_like(wp_url, '^https?://.*')
  ),

  joined AS (
    SELECT
      sr.sr_return_amt_inc_tax,
      sr.sr_reversed_charge,
      d.d_year,
      cc.cc_mkt_class,
      wp.wp_type,
      wp.wp_image_count,
      substring(wp.wp_url, 1, 30) AS url_prefix
    FROM sampled_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    JOIN filtered_web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
    WHERE cc.cc_call_center_sk IN (SELECT cc_call_center_sk FROM eligible_call_centers)
      AND d.d_year = 2020
  )
SELECT
  cc_mkt_class,
  COUNT(*) AS return_cnt,
  SUM(sr_return_amt_inc_tax) AS total_return_inc_tax,
  AVG(sr_return_amt_inc_tax) AS avg_return_inc_tax,
  CASE
    WHEN SUM(sr_reversed_charge) > 1000 THEN 'High Reversed'
    ELSE 'Normal'
  END AS reversed_charge_category,
  (SELECT AVG(sr_return_amt_inc_tax) FROM store_returns) AS overall_avg_return_inc_tax,
  MAX(url_prefix) AS sample_url_prefix
FROM joined
GROUP BY cc_mkt_class
HAVING COUNT(*) > 5
ORDER BY total_return_inc_tax DESC
LIMIT 100
