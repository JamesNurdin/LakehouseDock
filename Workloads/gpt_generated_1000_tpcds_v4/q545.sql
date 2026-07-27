WITH ws_enriched AS (
    SELECT
        sm.sm_carrier,
        sm.sm_contract,
        dd.d_year,
        dd.d_moy,
        ws.ws_net_profit,
        ws.ws_net_paid,
        ws.ws_web_page_sk,
        wp.wp_url,
        regexp_extract(wp.wp_url, '^https?://([^/]+)/', 1) AS domain,
        substring(wp.wp_url, 1, 15) AS url_prefix
    FROM tpcds.web_sales ws
    INNER JOIN tpcds.ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    INNER JOIN tpcds.date_dim dd
        ON ws.ws_sold_date_sk = dd.d_date_sk
    INNER JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE dd.d_date BETWEEN DATE '2000-01-01' AND DATE '2000-12-31'
      AND sm.sm_carrier LIKE 'U%'
      AND regexp_like(sm.sm_contract, '^A.*')
      AND wp.wp_url LIKE 'http%'
      AND substring(wp.wp_url, 1, 5) = 'https'
)
SELECT
    sm_carrier,
    domain,
    d_year,
    d_moy,
    SUM(ws_net_profit) AS total_profit,
    AVG(ws_net_paid) AS avg_paid,
    COUNT(*) AS order_count,
    CONCAT(sm_carrier, '_', domain) AS carrier_domain_key,
    url_prefix
FROM ws_enriched
GROUP BY
    sm_carrier,
    domain,
    d_year,
    d_moy,
    url_prefix
ORDER BY total_profit DESC
LIMIT 100
