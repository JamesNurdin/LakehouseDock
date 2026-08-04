WITH creation_join AS (
   SELECT
      wp.wp_web_page_sk,
      wp.wp_web_page_id,
      wp.wp_url,
      wp.wp_type,
      wp.wp_char_count,
      wp.wp_creation_date_sk,
      d.d_year AS creation_year,
      d.d_month_seq AS creation_month_seq,
      regexp_extract(wp.wp_url, 'https?://([^/]+)/', 1) AS domain,
      substring(wp.wp_url, 1, 20) AS url_prefix
   FROM web_page wp
   FULL OUTER JOIN date_dim d
     ON wp.wp_creation_date_sk = d.d_date_sk
),
access_join AS (
   SELECT
      wp.wp_web_page_sk,
      d.d_year AS access_year
   FROM web_page wp
   LEFT JOIN date_dim d
     ON wp.wp_access_date_sk = d.d_date_sk
),
intersect_keys AS (
   SELECT wp_web_page_sk FROM web_page WHERE wp_type LIKE 'C%'
   INTERSECT
   SELECT wp_web_page_sk FROM web_page WHERE wp_char_count > 1000
)
SELECT
   cj.creation_year,
   cj.domain,
   COUNT(DISTINCT cj.wp_web_page_id) AS page_count,
   SUM(cj.wp_char_count) AS total_chars,
   COUNT(DISTINCT aj.access_year) AS distinct_access_years,
   (SELECT COUNT(*) FROM web_page WHERE wp_autogen_flag = 'Y') AS autogen_total
FROM creation_join cj
LEFT JOIN access_join aj
   ON cj.wp_web_page_sk = aj.wp_web_page_sk
WHERE
   cj.wp_web_page_id NOT IN (SELECT wp_web_page_id FROM web_page WHERE wp_autogen_flag = 'Y')
   AND regexp_like(cj.wp_url, '^https?://[^/]+')
   AND cj.wp_type LIKE 'C%'
   AND cj.wp_web_page_sk IN (SELECT wp_web_page_sk FROM intersect_keys)
GROUP BY
   cj.creation_year,
   cj.domain
ORDER BY
   page_count DESC,
   cj.creation_year
LIMIT 100
