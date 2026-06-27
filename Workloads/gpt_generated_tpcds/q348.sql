WITH store_agg AS (
    SELECT
        ss_promo_sk,
        SUM(ss_net_profit) AS store_net_profit,
        SUM(ss_quantity) AS store_quantity,
        SUM(ss_ext_sales_price) AS store_sales_amount,
        SUM(ss_ext_discount_amt) AS store_discount_sum
    FROM store_sales
    GROUP BY ss_promo_sk
),
web_agg AS (
    SELECT
        ws_promo_sk,
        SUM(ws_net_profit) AS web_net_profit,
        SUM(ws_quantity) AS web_quantity,
        SUM(ws_ext_sales_price) AS web_sales_amount,
        SUM(ws_ext_discount_amt) AS web_discount_sum
    FROM web_sales
    GROUP BY ws_promo_sk
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    p.p_purpose,
    p.p_discount_active,
    COALESCE(s.store_net_profit, 0) AS store_net_profit,
    COALESCE(w.web_net_profit, 0) AS web_net_profit,
    (COALESCE(s.store_net_profit, 0) + COALESCE(w.web_net_profit, 0)) AS total_net_profit,
    COALESCE(s.store_quantity, 0) AS store_quantity,
    COALESCE(w.web_quantity, 0) AS web_quantity,
    (COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0)) AS total_quantity,
    COALESCE(s.store_sales_amount, 0) AS store_sales_amount,
    COALESCE(w.web_sales_amount, 0) AS web_sales_amount,
    (COALESCE(s.store_sales_amount, 0) + COALESCE(w.web_sales_amount, 0)) AS total_sales_amount,
    COALESCE(s.store_discount_sum, 0) AS store_discount_sum,
    COALESCE(w.web_discount_sum, 0) AS web_discount_sum,
    (COALESCE(s.store_discount_sum, 0) + COALESCE(w.web_discount_sum, 0)) AS total_discount_sum,
    CASE
        WHEN (COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0)) > 0
        THEN (COALESCE(s.store_discount_sum, 0) + COALESCE(w.web_discount_sum, 0)) / (COALESCE(s.store_quantity, 0) + COALESCE(w.web_quantity, 0))
        ELSE NULL
    END AS avg_discount_per_item
FROM promotion p
LEFT JOIN store_agg s ON s.ss_promo_sk = p.p_promo_sk
LEFT JOIN web_agg w ON w.ws_promo_sk = p.p_promo_sk
ORDER BY total_net_profit DESC
LIMIT 10
