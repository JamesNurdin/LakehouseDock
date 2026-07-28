WITH sales_enriched AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_promo_sk,
        ws.ws_net_profit,
        p.p_promo_id,
        p.p_promo_name,
        -- extract the first numeric block from the promotion name
        regexp_extract(p.p_promo_name, '[0-9]+') AS promo_number,
        -- flag promotions whose purpose mentions discount or sale (case‑insensitive)
        CASE WHEN regexp_like(p.p_purpose, '(?i)discount|sale') THEN 1 ELSE 0 END AS is_discount_promo
    FROM web_sales ws
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    -- keep only promotions whose name follows a pattern like ABC123
    WHERE regexp_like(p.p_promo_name, '^[A-Z]{3}[0-9]{3}$')
)
SELECT
    wsit.web_company_name,
    substr(wsit.web_name, 1, 10) AS short_name,
    COUNT(DISTINCT sp.p_promo_id) AS distinct_promo_cnt,
    SUM(sp.ws_net_profit) AS total_net_profit,
    CASE
        WHEN SUM(sp.ws_net_profit) > 10000 THEN 'HIGH'
        WHEN SUM(sp.ws_net_profit) > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category
FROM sales_enriched sp
JOIN web_site wsit
  ON sp.ws_web_site_sk = wsit.web_site_sk
WHERE wsit.web_name LIKE '%shop%'
  AND wsit.web_company_name LIKE 'a%'
GROUP BY wsit.web_company_name, substr(wsit.web_name, 1, 10)
ORDER BY total_net_profit DESC
LIMIT 100
