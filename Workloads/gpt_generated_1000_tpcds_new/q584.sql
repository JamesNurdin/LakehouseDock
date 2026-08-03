SELECT d.d_quarter_name,
       COUNT(*) AS page_count
FROM   web_page wp
JOIN   date_dim d
       ON wp.wp_creation_date_sk = d.d_date_sk
WHERE  d.d_fy_quarter_seq = 13
  AND  wp.wp_max_ad_count > 2
GROUP BY d.d_quarter_name
