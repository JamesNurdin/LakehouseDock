WITH site_sales AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_promo_sk,
        ws.ws_quantity,
        p.p_discount_active,
        ws.ws_net_paid_inc_tax,
        CASE WHEN p.p_discount_active = 'Y' THEN ws.ws_net_profit * 0.9 ELSE ws.ws_net_profit END AS adjusted_profit
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN web_site s
        ON ws.ws_web_site_sk = s.web_site_sk
    WHERE
        p.p_channel_event = 'N'                           -- predicate 1
        AND p.p_purpose <> 'Unknown'                      -- predicate 2
        AND ws.ws_sold_date_sk BETWEEN 2451433 AND 2452394 -- predicate 3
        AND s.web_tax_percentage > 0.05                  -- predicate 4
        AND s.web_zip LIKE '9%'                           -- predicate 5
)
SELECT
    s.web_name,
    s.web_state,
    SUM(ss.adjusted_profit) AS total_adjusted_profit,
    AVG(ss.adjusted_profit) AS avg_adjusted_profit,
    RANK() OVER (ORDER BY SUM(ss.adjusted_profit) DESC) AS profit_rank,
    CASE
        WHEN SUM(ss.adjusted_profit) > (
            SELECT AVG(total_adj)
            FROM (
                SELECT SUM(CASE WHEN p.p_discount_active = 'Y' THEN ws.ws_net_profit * 0.9 ELSE ws.ws_net_profit END) AS total_adj
                FROM web_sales ws
                JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
                JOIN web_site s2 ON ws.ws_web_site_sk = s2.web_site_sk
                WHERE p.p_channel_event = 'N'
                  AND p.p_purpose <> 'Unknown'
                  AND ws.ws_sold_date_sk BETWEEN 2451433 AND 2452394
                  AND s2.web_tax_percentage > 0.05
                  AND s2.web_zip LIKE '9%'
            ) t
        ) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS performance_flag
FROM site_sales ss
JOIN web_site s
    ON ss.ws_web_site_sk = s.web_site_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_promo_sk = ss.ws_promo_sk
      AND p2.p_channel_tv = 'Y'
)
GROUP BY s.web_name, s.web_state
ORDER BY total_adjusted_profit DESC
LIMIT 20
