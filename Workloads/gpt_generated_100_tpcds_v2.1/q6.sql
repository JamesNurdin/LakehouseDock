SELECT date_dim.d_year, web_page.wp_type, COUNT(*) AS page_count
FROM web_page
JOIN date_dim ON web_page.wp_creation_date_sk = date_dim.d_date_sk
WHERE web_page.wp_type IN ('order', 'welcome')
  AND date_dim.d_year = 2000
GROUP BY date_dim.d_year, web_page.wp_type
ORDER BY page_count DESC
LIMIT 100
