WITH promo_info AS (
    SELECT p_promo_sk,
           p_promo_id,
           p_promo_name
    FROM promotion
),
combined_sales AS (
    SELECT
        s.s_store_sk AS entity_id,
        s.s_store_name AS entity_name,
        'Store' AS entity_type,
        pi.p_promo_id AS promotion_id,
        pi.p_promo_name AS promotion_name,
        SUM(ss.ss_net_profit) AS total_net_profit,
        SUM(ss.ss_quantity) AS total_quantity,
        CASE WHEN SUM(ss.ss_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promo_info pi ON ss.ss_promo_sk = pi.p_promo_sk
    WHERE s.s_state = 'CA'
    GROUP BY s.s_store_sk,
             s.s_store_name,
             pi.p_promo_id,
             pi.p_promo_name

    UNION ALL

    SELECT
        w.web_site_sk AS entity_id,
        w.web_name AS entity_name,
        'Web' AS entity_type,
        pi.p_promo_id AS promotion_id,
        pi.p_promo_name AS promotion_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        CASE WHEN SUM(ws.ws_net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM web_sales ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN promo_info pi ON ws.ws_promo_sk = pi.p_promo_sk
    WHERE w.web_city = 'Seattle'
    GROUP BY w.web_site_sk,
             w.web_name,
             pi.p_promo_id,
             pi.p_promo_name
)
SELECT
    cs.entity_id,
    cs.entity_name,
    cs.entity_type,
    cs.promotion_id,
    cs.promotion_name,
    cs.total_net_profit,
    cs.total_quantity,
    cs.profit_category,
    CASE
        WHEN cs.entity_type = 'Store' THEN (
            SELECT COUNT(DISTINCT ss2.ss_customer_sk)
            FROM store_sales ss2
            WHERE ss2.ss_store_sk = cs.entity_id
        )
        WHEN cs.entity_type = 'Web' THEN (
            SELECT COUNT(DISTINCT ws2.ws_bill_customer_sk)
            FROM web_sales ws2
            WHERE ws2.ws_web_site_sk = cs.entity_id
        )
        ELSE NULL
    END AS distinct_customer_count
FROM combined_sales cs
ORDER BY cs.total_net_profit DESC
LIMIT 100
