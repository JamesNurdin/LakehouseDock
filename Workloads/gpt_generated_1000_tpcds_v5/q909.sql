WITH filtered_web AS (
    SELECT wp_web_page_sk,
           wp_url,
           wp_type,
           wp_image_count,
           wp_creation_date_sk
    FROM web_page
    WHERE regexp_like(wp_url, '^https?://[^/]+\\.com$')
      AND wp_type LIKE 'c%'
      AND wp_image_count > (
          SELECT avg(wp_image_count)
          FROM web_page AS wp2
          WHERE wp2.wp_type = web_page.wp_type
      )
)
SELECT d.d_year,
       fw.wp_type,
       COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions,
       SUM(ss.ss_net_profit) AS total_net_profit,
       CONCAT('Type-', fw.wp_type) AS type_label,
       regexp_extract(fw.wp_url, 'https?://([^/]+)/', 1) AS domain
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN filtered_web fw ON fw.wp_creation_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 2000 AND 2002
GROUP BY d.d_year,
         fw.wp_type,
         fw.wp_url
HAVING SUM(ss.ss_net_profit) > 0
ORDER BY total_net_profit DESC
LIMIT 100
