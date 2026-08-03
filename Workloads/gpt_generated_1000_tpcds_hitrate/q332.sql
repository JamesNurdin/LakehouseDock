SELECT
  wp_web_page_id,
  wp_url,
  wp_link_count
FROM
  web_page
WHERE
  wp_link_count >= 10
  AND wp_rec_end_date = DATE '2000-09-02'
