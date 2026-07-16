SELECT d.d_year,
       wp.wp_type,
       COUNT(DISTINCT wp.wp_web_page_sk) AS page_cnt,
       SUM(p.p_cost) AS total_promo_cost
FROM web_page wp
INNER JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
INNER JOIN promotion p ON p.p_start_date_sk = d.d_date_sk
WHERE d.d_year = 1923
  AND p.p_discount_active = 'N'
GROUP BY d.d_year, wp.wp_type
ORDER BY d.d_year, wp.wp_type
