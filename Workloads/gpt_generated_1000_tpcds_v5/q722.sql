WITH web_agg AS (
    SELECT
        w.web_name AS source_name,
        p.p_promo_name AS promo_name,
        SUM(ws.ws_net_profit) AS total_amount
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE w.web_name LIKE '%Online%'
      AND p.p_discount_active = 'Y'
    GROUP BY w.web_name, p.p_promo_name
    HAVING SUM(ws.ws_net_profit) > 5000
)
SELECT
    source_name,
    promo_name,
    total_amount
FROM web_agg

UNION ALL

SELECT
    cp.cp_department AS source_name,
    'Catalog Return' AS promo_name,
    SUM(cr.cr_net_loss) AS total_amount
FROM catalog_returns cr
JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
WHERE cp.cp_department IS NOT NULL
GROUP BY cp.cp_department
HAVING SUM(cr.cr_net_loss) > 5000

ORDER BY total_amount DESC
LIMIT 100
