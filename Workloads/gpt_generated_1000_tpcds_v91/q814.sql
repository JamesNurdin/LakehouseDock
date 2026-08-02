WITH sub_a AS (
   SELECT
      c.c_customer_id AS customer_id,
      c.c_first_name AS first_name,
      c.c_last_name AS last_name,
      COUNT(DISTINCT wp.wp_web_page_sk) AS page_count,
      SUM(wp.wp_link_count) AS total_links,
      CASE WHEN SUM(wp.wp_link_count) > 100 THEN 'High' ELSE 'Low' END AS link_volume_category,
      (SELECT AVG(wp2.wp_link_count) FROM web_page wp2) AS avg_link_global,
      'AdCount' AS source_label
   FROM web_page wp
   JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
   WHERE wp.wp_max_ad_count > 1
     AND wp.wp_rec_end_date >= DATE '2000-01-01'
   GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
),
sub_b AS (
   SELECT
      c.c_customer_id AS customer_id,
      c.c_first_name AS first_name,
      c.c_last_name AS last_name,
      COUNT(DISTINCT wp.wp_web_page_sk) AS page_count,
      SUM(wp.wp_link_count) AS total_links,
      CASE WHEN SUM(wp.wp_link_count) > 100 THEN 'High' ELSE 'Low' END AS link_volume_category,
      (SELECT AVG(wp2.wp_link_count) FROM web_page wp2) AS avg_link_global,
      'YorkCounty' AS source_label
   FROM web_page wp
   JOIN customer c ON wp.wp_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
   WHERE ca.ca_county = 'York County'
     AND EXISTS (
         SELECT 1
         FROM web_page wp2
         WHERE wp2.wp_customer_sk = c.c_customer_sk
           AND wp2.wp_link_count > 10
     )
   GROUP BY c.c_customer_id, c.c_first_name, c.c_last_name
)
SELECT
   ROW_NUMBER() OVER (ORDER BY total_links DESC) AS rn,
   customer_id,
   first_name,
   last_name,
   page_count,
   total_links,
   link_volume_category,
   avg_link_global,
   source_label
FROM (
   SELECT
      customer_id,
      first_name,
      last_name,
      page_count,
      total_links,
      link_volume_category,
      avg_link_global,
      source_label
   FROM sub_a
   UNION ALL
   SELECT
      customer_id,
      first_name,
      last_name,
      page_count,
      total_links,
      link_volume_category,
      avg_link_global,
      source_label
   FROM sub_b
) AS combined
ORDER BY total_links DESC
LIMIT 100
