-- Goal: Analyze monthly sales performance of promotions whose channel details contain the word "fees" and that were active on days when a web page URL contains "example.com".
-- The query demonstrates string processing (REGEXP_LIKE, REGEXP_EXTRACT, LIKE, CONCAT), uses DISTINCT via COUNT(DISTINCT), joins across the allowed tables, groups, orders, and limits the result.

SELECT
    d.d_year,
    d.d_month_seq,
    p.p_promo_id,
    CONCAT(p.p_promo_id, ':', p.p_promo_name) AS promo_label,
    MIN(REGEXP_EXTRACT(wp.wp_url, 'https?://([^/]+)/', 1)) AS domain,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
WHERE REGEXP_LIKE(p.p_channel_details, '(?i)fees')
  AND wp.wp_url LIKE '%example.com%'
GROUP BY
    d.d_year,
    d.d_month_seq,
    p.p_promo_id,
    p.p_promo_name
ORDER BY total_sales DESC
LIMIT 100
