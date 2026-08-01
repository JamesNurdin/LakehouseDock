WITH sales_dates AS (
    SELECT d.d_date
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE ss.ss_net_profit > 0
    GROUP BY d.d_date
),
return_dates AS (
    SELECT d.d_date
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE cr.cr_net_loss > 5000
    GROUP BY d.d_date
),
common_dates AS (
    SELECT d_date FROM sales_dates
    INTERSECT
    SELECT d_date FROM return_dates
),
url_stats AS (
    SELECT COUNT(*) AS sale_segment_cnt
    FROM web_page wp
    CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS t(segment)
    WHERE regexp_like(segment, '(?i)sale')
)
SELECT
    s.s_store_name,
    p.p_promo_name,
    d.d_year,
    CONCAT(s.s_store_name, ' | ', p.p_promo_name) AS store_promo_concat,
    REGEXP_EXTRACT(p.p_promo_name, '(\\d{4})') AS promo_year_code,
    SUM(ss.ss_net_profit) AS total_net_profit,
    COUNT(*) AS transaction_cnt,
    (SELECT sale_segment_cnt FROM url_stats) AS total_sale_url_segments
FROM store_sales ss
JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
WHERE d.d_date IN (SELECT d_date FROM common_dates)
  AND s.s_store_name LIKE '%Market%'
  AND REGEXP_LIKE(p.p_promo_name, '202[0-3]')
GROUP BY CUBE (s.s_store_name, p.p_promo_name, d.d_year)
ORDER BY total_net_profit DESC
LIMIT 100
