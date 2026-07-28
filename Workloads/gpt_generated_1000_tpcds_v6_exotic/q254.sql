WITH filtered_sales AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_net_paid,
        ws.ws_quantity,
        ws.ws_promo_sk,
        ws.ws_web_site_sk,
        p.p_promo_name,
        d.d_date,
        w.web_name,
        sm.sm_type
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE regexp_like(p.p_promo_name, '(?i)discount')
      AND w.web_name LIKE '%Online%'
      AND d.d_year = 2002
)
SELECT
    fs.ws_order_number,
    fs.d_date,
    fs.web_name,
    fs.p_promo_name,
    fs.ws_quantity,
    fs.ws_net_paid,
    regexp_extract(fs.p_promo_name, '(?i)(discount\s*\d+)%?', 1) AS discount_pct_extracted,
    CONCAT(fs.web_name, ' - ', fs.p_promo_name) AS site_promo_desc,
    ROW_NUMBER() OVER (PARTITION BY fs.web_name ORDER BY fs.ws_net_paid DESC) AS rn_per_site
FROM filtered_sales fs
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr
    WHERE wr.wr_order_number = fs.ws_order_number
)
ORDER BY fs.ws_net_paid DESC
LIMIT 100
