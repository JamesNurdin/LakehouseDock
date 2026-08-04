WITH
  -- Aggregate return amounts per web page
  agg_returns AS (
    SELECT
      wp.wp_web_page_sk,
      wp.wp_url,
      wp.wp_type,
      SUM(wr.wr_return_amt) AS total_return_amt,
      SUM(wr.wr_return_tax) AS total_return_tax,
      COUNT(*) AS return_cnt
    FROM web_page wp
    LEFT JOIN web_returns wr
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_end_date >= DATE '2000-01-01'
    GROUP BY wp.wp_web_page_sk, wp.wp_url, wp.wp_type
  ),

  -- Pages that do NOT have any return with a high fee (anti‑join)
  pages_no_high_fee AS (
    SELECT
      wp.wp_web_page_sk,
      wp.wp_url,
      wp.wp_type,
      wp.wp_char_count,
      wp.wp_max_ad_count
    FROM web_page wp
    WHERE NOT EXISTS (
      SELECT 1
      FROM web_returns wr
      WHERE wr.wr_web_page_sk = wp.wp_web_page_sk
        AND wr.wr_fee > 80
    )
  ),

  -- Full outer join keeping unmatched rows from both sides
  full_combined AS (
    SELECT
      COALESCE(ar.wp_web_page_sk, pnh.wp_web_page_sk) AS web_page_sk,
      COALESCE(ar.wp_url, pnh.wp_url) AS url,
      COALESCE(ar.wp_type, pnh.wp_type) AS type,
      ar.total_return_amt,
      ar.total_return_tax,
      ar.return_cnt,
      pnh.wp_char_count,
      pnh.wp_max_ad_count
    FROM agg_returns ar
    FULL OUTER JOIN pages_no_high_fee pnh
      ON ar.wp_web_page_sk = pnh.wp_web_page_sk
  ),

  -- First set for the UNION: pages with more than 5 returns
  set1 AS (
    SELECT
      web_page_sk,
      url,
      type,
      total_return_amt,
      total_return_tax,
      return_cnt,
      wp_char_count,
      wp_max_ad_count,
      ROW_NUMBER() OVER (ORDER BY total_return_amt DESC) AS rn
    FROM full_combined
    WHERE return_cnt > 5
  ),

  -- Second set for the UNION: pages with large character count and no returns
  set2 AS (
    SELECT
      web_page_sk,
      url,
      type,
      total_return_amt,
      total_return_tax,
      return_cnt,
      wp_char_count,
      wp_max_ad_count,
      ROW_NUMBER() OVER (ORDER BY wp_char_count DESC) AS rn
    FROM full_combined
    WHERE wp_char_count > 3000 AND return_cnt IS NULL
  ),

  -- Small dimension table for the cross join
  dim_const AS (
    SELECT 1 AS const_id, 'A' AS const_flag UNION ALL
    SELECT 2, 'B' UNION ALL
    SELECT 3, 'C'
  )

SELECT
  d.const_id,
  d.const_flag,
  s.web_page_sk,
  s.url,
  s.type,
  s.total_return_amt,
  s.total_return_tax,
  s.return_cnt,
  s.wp_char_count,
  s.wp_max_ad_count,
  s.rn
FROM (
  SELECT * FROM set1
  UNION ALL
  SELECT * FROM set2
) s
CROSS JOIN dim_const d
ORDER BY s.total_return_amt DESC NULLS LAST, d.const_id
LIMIT 100
