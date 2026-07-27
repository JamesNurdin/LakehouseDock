WITH cs_agg AS (
        SELECT
            cc.cc_call_center_sk,
            cc.cc_city,
            p.p_promo_sk,
            p.p_promo_name,
            SUM(cs.cs_net_profit) AS cs_total_profit,
            COUNT(*) AS cs_txn_cnt
        FROM catalog_sales cs
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        WHERE regexp_like(cc.cc_city, '(?i)York')
          AND p.p_promo_name LIKE 'New%'
        GROUP BY cc.cc_call_center_sk, cc.cc_city, p.p_promo_sk, p.p_promo_name
    ),
    ws_agg AS (
        SELECT
            p.p_promo_sk,
            SUM(ws.ws_net_profit) AS ws_total_profit,
            COUNT(*) AS ws_txn_cnt
        FROM web_sales ws
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        WHERE regexp_like(p.p_promo_name, '^New[ A-Za-z]*')
        GROUP BY p.p_promo_sk
    ),
    combined AS (
        SELECT
            cs.cc_call_center_sk,
            cs.cc_city,
            cs.p_promo_name,
            cs.cs_total_profit,
            ws.ws_total_profit,
            (cs.cs_total_profit + ws.ws_total_profit) AS total_profit,
            CASE
                WHEN (cs.cs_total_profit + ws.ws_total_profit) > 100000 THEN 'HIGH'
                ELSE 'LOW'
            END AS profit_category,
            cs.p_promo_sk
        FROM cs_agg cs
        LEFT JOIN ws_agg ws ON cs.p_promo_sk = ws.p_promo_sk
        WHERE EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_sk = cs.p_promo_sk
              AND regexp_extract(p2.p_purpose, '(\\w+)', 1) = 'Discount'
        )
    )
SELECT
    cc_call_center_sk,
    cc_city,
    p_promo_name,
    total_profit,
    profit_category,
    CONCAT('Center ', CAST(cc_call_center_sk AS varchar), ': ', p_promo_name) AS label
FROM combined
ORDER BY total_profit DESC
LIMIT 100
