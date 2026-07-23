WITH
    store_agg AS (
        SELECT
            ss.ss_promo_sk AS promo_sk,
            SUM(ss.ss_net_profit) AS store_net_profit,
            SUM(ss.ss_ext_sales_price) AS store_ext_sales,
            COUNT(DISTINCT ss.ss_customer_sk) AS store_customer_count
        FROM store_sales ss
        GROUP BY ss.ss_promo_sk
    ),
    web_agg AS (
        SELECT
            ws.ws_promo_sk AS promo_sk,
            SUM(ws.ws_net_profit) AS web_net_profit,
            SUM(ws.ws_ext_sales_price) AS web_ext_sales,
            COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customer_count
        FROM web_sales ws
        GROUP BY ws.ws_promo_sk
    ),
    promo_filtered AS (
        SELECT
            p.p_promo_sk,
            p.p_promo_name,
            p.p_purpose,
            regexp_extract(p.p_promo_name, '^(.{3})', 1) AS promo_name_prefix,
            CASE WHEN p.p_purpose = 'Unknown' THEN 'Other' ELSE p.p_purpose END AS purpose_category
        FROM promotion p
        WHERE regexp_like(p.p_promo_name, '[aeiou]')
          AND p.p_promo_name LIKE '___%'
    )
SELECT
    CONCAT(pf.promo_name_prefix, '-', pf.purpose_category) AS promo_label,
    pf.promo_name_prefix,
    pf.purpose_category,
    COALESCE(sa.store_net_profit, 0) AS store_net_profit,
    COALESCE(wa.web_net_profit, 0) AS web_net_profit,
    (COALESCE(sa.store_net_profit, 0) - COALESCE(wa.web_net_profit, 0)) AS profit_diff,
    CASE
        WHEN COALESCE(sa.store_net_profit, 0) > COALESCE(wa.web_net_profit, 0) THEN 'Store Higher'
        WHEN COALESCE(sa.store_net_profit, 0) < COALESCE(wa.web_net_profit, 0) THEN 'Web Higher'
        ELSE 'Equal'
    END AS profit_comparison
FROM promo_filtered pf
LEFT JOIN store_agg sa ON sa.promo_sk = pf.p_promo_sk
LEFT JOIN web_agg wa ON wa.promo_sk = pf.p_promo_sk
ORDER BY profit_diff DESC
LIMIT 100
