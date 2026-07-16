SELECT
  d.d_year,
  d.d_month_seq,
  CASE WHEN w.w_state IN ('CA', 'NY', 'TX') THEN 'Major' ELSE 'Other' END AS region_category,
  s.s_market_id,
  SUM(i.inv_quantity_on_hand) AS total_quantity_on_hand,
  AVG(i.inv_quantity_on_hand) AS avg_quantity_on_hand,
  COUNT(DISTINCT i.inv_item_sk) AS distinct_item_count,
  COUNT(DISTINCT s.s_store_sk) AS distinct_store_count,
  SUM(wp.wp_image_count) AS total_images_created,
  SUM(wp2.wp_image_count) AS total_images_accessed,
  SUM(wp.wp_max_ad_count) AS total_ads_created,
  SUM(wp2.wp_max_ad_count) AS total_ads_accessed
FROM date_dim d
JOIN inventory i
  ON i.inv_date_sk = d.d_date_sk
JOIN warehouse w
  ON i.inv_warehouse_sk = w.w_warehouse_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d.d_date_sk
JOIN web_page wp2
  ON wp2.wp_access_date_sk = d.d_date_sk
WHERE d.d_year >= 2015
  AND w.w_gmt_offset IS NOT NULL
GROUP BY
  d.d_year,
  d.d_month_seq,
  CASE WHEN w.w_state IN ('CA', 'NY', 'TX') THEN 'Major' ELSE 'Other' END,
  s.s_market_id
HAVING SUM(i.inv_quantity_on_hand) > 100
ORDER BY total_quantity_on_hand DESC
LIMIT 100
