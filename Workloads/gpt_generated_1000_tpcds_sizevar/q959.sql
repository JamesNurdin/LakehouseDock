WITH sampled_promotions AS (
    SELECT *
    FROM promotion
    TABLESAMPLE BERNOULLI (5)
),
promo_details AS (
    SELECT
        sp.p_promo_sk,
        sp.p_promo_name,
        regexp_extract(sp.p_promo_id, '(\\d+)', 1) AS promo_id_num,
        sp.p_discount_active,
        sp.p_promo_name || ' - ' || sp.p_promo_id AS promo_full_desc
    FROM sampled_promotions sp
    WHERE regexp_like(sp.p_promo_name, '^.*Sale.*$')
)
SELECT
    pd.promo_full_desc,
    d.d_year,
    url.domain,
    substring(CAST(ws.ws_sold_date_sk AS varchar), 1, 4) AS sold_date_key_prefix,
    COUNT(DISTINCT ws.ws_order_number) AS orders,
    SUM(ws.ws_net_paid) AS total_net_paid,
    AVG(ws.ws_ext_discount_amt) AS avg_discount
FROM
    promo_details pd
JOIN
    web_sales ws
    ON ws.ws_promo_sk = pd.p_promo_sk
JOIN
    date_dim d
    ON ws.ws_sold_date_sk = d.d_date_sk
JOIN
    web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
CROSS JOIN LATERAL (
    SELECT regexp_extract(wp.wp_url, '^(https?://[^/]+)', 1) AS domain
    FROM web_page wp
    WHERE wp.wp_web_page_sk = ws.ws_web_page_sk
) AS url
WHERE
    ws.ws_item_sk IN (
        SELECT cs.cs_item_sk
        FROM catalog_sales cs
        WHERE cs.cs_ext_sales_price > 5000
    )
    AND wsite.web_name LIKE '%Shop%'
    AND regexp_like(wsite.web_name, '^.*Online.*$')
GROUP BY
    pd.promo_full_desc,
    d.d_year,
    url.domain,
    substring(CAST(ws.ws_sold_date_sk AS varchar), 1, 4)
ORDER BY
    total_net_paid DESC
LIMIT 100
