WITH ss_agg AS (
    SELECT
        ss_promo_sk,
        SUM(ss_net_profit) AS total_store_profit,
        COUNT(DISTINCT ss_ticket_number) AS order_cnt
    FROM store_sales
    WHERE ss_net_profit > 0
    GROUP BY ss_promo_sk
)
SELECT
    cc.cc_name,
    sm.sm_carrier,
    p.p_promo_name,
    SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
    ss_agg.total_store_profit,
    CASE
        WHEN SUM(cs.cs_ext_sales_price) > ss_agg.total_store_profit THEN 'Catalog higher'
        ELSE 'Store higher'
    END AS sales_comparison,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_orders
FROM catalog_sales cs
JOIN call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN ss_agg
    ON ss_agg.ss_promo_sk = p.p_promo_sk
-- Re‑use tables under different aliases for additional joins
JOIN promotion p2
    ON cs.cs_promo_sk = p2.p_promo_sk
JOIN promotion p3
    ON cs.cs_promo_sk = p3.p_promo_sk
JOIN call_center cc2
    ON cs.cs_call_center_sk = cc2.cc_call_center_sk
JOIN ship_mode sm2
    ON cs.cs_ship_mode_sk = sm2.sm_ship_mode_sk
JOIN store_sales ss_raw
    ON ss_raw.ss_promo_sk = p.p_promo_sk
WHERE cc.cc_state = 'CA'
  AND sm.sm_type = 'AIR'
GROUP BY
    cc.cc_name,
    sm.sm_carrier,
    p.p_promo_name,
    ss_agg.total_store_profit
ORDER BY catalog_sales_amount DESC
LIMIT 100
