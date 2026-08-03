WITH
    page_filter AS (
        SELECT
            wp_web_page_sk,
            wp_url,
            wp_type,
            wp_char_count,
            wp_image_count,
            wp_rec_end_date
        FROM web_page
        WHERE wp_web_page_sk IN (
            SELECT ws_web_page_sk
            FROM web_sales
            WHERE ws_ext_ship_cost > 5000
        )
        AND regexp_like(wp_url, '^https?://.*(news|article).*')
        AND wp_url LIKE '%example.com%'
    ),
    hour_dim AS (
        SELECT t_time_sk, t_hour, t_am_pm
        FROM time_dim
        WHERE t_hour BETWEEN 8 AND 12
    ),
    ampm_vals AS (
        SELECT ampm
        FROM (VALUES 'AM', 'PM') AS v(ampm)
    ),
    sales_fact AS (
        SELECT
            ws.ws_order_number,
            ws.ws_ext_sales_price,
            ws.ws_ext_ship_cost,
            ws.ws_web_page_sk,
            hd.t_hour,
            hd.t_am_pm
        FROM web_sales ws
        JOIN hour_dim hd ON ws.ws_sold_time_sk = hd.t_time_sk
        JOIN ampm_vals am ON hd.t_am_pm = am.ampm
    )
SELECT
    sf.t_hour,
    pf.wp_type,
    COUNT(DISTINCT sf.ws_order_number) AS orders,
    SUM(sf.ws_ext_sales_price) AS sales_amount,
    SUM(CASE WHEN sf.ws_ext_ship_cost > 4000 THEN sf.ws_ext_ship_cost ELSE 0 END) AS high_ship_cost,
    CONCAT('H', CAST(sf.t_hour AS VARCHAR), '_', pf.wp_type) AS hour_type_key,
    regexp_extract(pf.wp_url, '(?i)(news|article)') AS keyword,
    pf.wp_url,
    SUM(sf.ws_ext_sales_price) / (
        SELECT MAX(ws_ext_sales_price) FROM web_sales
    ) AS sales_vs_max
FROM sales_fact sf
RIGHT OUTER JOIN page_filter pf
    ON sf.ws_web_page_sk = pf.wp_web_page_sk
GROUP BY
    sf.t_hour,
    pf.wp_type,
    CONCAT('H', CAST(sf.t_hour AS VARCHAR), '_', pf.wp_type),
    regexp_extract(pf.wp_url, '(?i)(news|article)'),
    pf.wp_url
ORDER BY sales_amount DESC
LIMIT 100
