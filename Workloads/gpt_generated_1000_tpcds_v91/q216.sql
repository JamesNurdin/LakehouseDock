SELECT d.d_year,
       COUNT(*) AS page_count,
       SUM(wp.wp_link_count) AS total_links
FROM web_page wp
JOIN date_dim d
  ON wp.wp_creation_date_sk = d.d_date_sk
WHERE wp.wp_autogen_flag = 'N'
  AND d.d_year = 2000
GROUP BY d.d_year
ORDER BY page_count DESC
