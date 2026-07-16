WITH page_metrics AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_web_page_id,
        wp.wp_type,
        wp.wp_url,
        regexp_extract(wp.wp_url, 'https?://([^/]+)') AS domain,
        length(wp.wp_url) AS url_len,
        cardinality(split(wp.wp_url, '/')) - 1 AS slash_count,
        cardinality(regexp_extract_all(lower(wp.wp_url), 'sale')) AS sale_occurrences,
        translate(wp.wp_url, 'aeiou', 'AEIOU') AS url_vowel_upper,
        reverse(wp.wp_type) AS rev_type,
        substring(wp.wp_url, 1, 10) AS url_prefix,
        concat('Page-', wp.wp_web_page_id, '-', regexp_extract(wp.wp_url, 'https?://([^/]+)')) AS page_label
    FROM web_page wp
    WHERE lower(wp.wp_url) LIKE '%product%'
)
SELECT
    pm.wp_web_page_id,
    pm.wp_type,
    pm.domain,
    pm.url_len,
    pm.slash_count,
    pm.sale_occurrences,
    pm.url_vowel_upper,
    pm.rev_type,
    pm.url_prefix,
    pm.page_label,
    ws_agg.total_net_paid,
    ws_agg.total_quantity,
    ws_agg.avg_tax,
    ws_agg.distinct_orders,
    ws_agg.site_label,
    concat(pm.page_label, '-', ws_agg.site_label) AS full_label
FROM page_metrics pm
JOIN (
    SELECT
        ws.ws_web_page_sk,
        sum(ws.ws_net_paid) AS total_net_paid,
        sum(ws.ws_quantity) AS total_quantity,
        avg(ws.ws_ext_tax) AS avg_tax,
        count(distinct ws.ws_order_number) AS distinct_orders,
        concat('Site-', wsl.web_site_id, '-', wsl.web_name) AS site_label
    FROM web_sales ws
    JOIN web_site wsl ON ws.ws_web_site_sk = wsl.web_site_sk
    GROUP BY ws.ws_web_page_sk, wsl.web_site_id, wsl.web_name
) ws_agg
ON pm.wp_web_page_sk = ws_agg.ws_web_page_sk
ORDER BY ws_agg.total_net_paid DESC
LIMIT 100
