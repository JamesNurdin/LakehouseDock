WITH promo_pages AS (
    SELECT
        wp.wp_web_page_sk,
        wp.wp_url,
        wp.wp_type,
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        CASE
            WHEN regexp_like(wp.wp_url, 'promo[0-9]+') THEN regexp_extract(wp.wp_url, 'promo([0-9]+)', 1)
            ELSE NULL
        END AS extracted_promo_id,
        CASE
            WHEN wp.wp_autogen_flag = 'Y' THEN 'AutoGen'
            ELSE 'Manual'
        END AS page_origin
    FROM web_page wp
    JOIN web_sales ws ON wp.wp_web_page_sk = ws.ws_web_page_sk
    WHERE wp.wp_url LIKE '%promo%'
),
agg_promo AS (
    SELECT
        p.p_promo_name,
        p.p_promo_id,
        s.web_name,
        d.d_year,
        d.d_moy,
        SUM(fp.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT fp.ws_order_number) AS distinct_orders,
        CASE
            WHEN SUM(fp.ws_net_profit) > 50000 THEN 'High'
            WHEN SUM(fp.ws_net_profit) BETWEEN 20000 AND 50000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_category,
        CONCAT(p.p_promo_id, '-', s.web_name) AS promo_site_key,
        fp.extracted_promo_id
    FROM promo_pages fp
    JOIN promotion p ON fp.ws_promo_sk = p.p_promo_sk
    JOIN web_site s ON fp.ws_web_site_sk = s.web_site_sk
    JOIN date_dim d ON fp.ws_sold_date_sk = d.d_date_sk
    GROUP BY
        p.p_promo_name,
        p.p_promo_id,
        s.web_name,
        d.d_year,
        d.d_moy,
        fp.extracted_promo_id,
        CONCAT(p.p_promo_id, '-', s.web_name)
)
SELECT
    ap.p_promo_name,
    ap.p_promo_id,
    ap.web_name,
    CONCAT(CAST(ap.d_year AS varchar), '-', LPAD(CAST(ap.d_moy AS varchar), 2, '0')) AS sale_month,
    ap.total_net_profit,
    ap.distinct_orders,
    ap.profit_category,
    ap.promo_site_key,
    ap.extracted_promo_id,
    ROW_NUMBER() OVER (PARTITION BY ap.p_promo_name ORDER BY ap.total_net_profit DESC) AS promo_rank
FROM agg_promo ap
ORDER BY ap.total_net_profit DESC
LIMIT 100
