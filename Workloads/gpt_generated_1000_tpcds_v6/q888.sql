WITH cs_base AS (
    SELECT
        cs.cs_promo_sk,
        cs.cs_net_profit,
        cs.cs_call_center_sk,
        cs.cs_sold_date_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk
    FROM tpcds.catalog_sales cs
)
SELECT
    p.p_promo_id,
    p.p_promo_name,
    CONCAT(cc.cc_city, ', ', cc.cc_state) AS call_center_location,
    REGEXP_EXTRACT(w.w_street_name, '^(\\w+)', 1) AS street_prefix,
    SUM(cs.cs_net_profit) AS total_profit,
    COUNT(*) AS sales_cnt
FROM cs_base cs
JOIN tpcds.date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
WHERE d.d_year = 2001
  AND p.p_promo_name LIKE '%Discount%'
  AND REGEXP_LIKE(cc.cc_name, '^.*Center.*$')
  AND REGEXP_LIKE(w.w_street_name, '^[A-Z]')
  AND EXISTS (
        SELECT 1
        FROM tpcds.catalog_sales cs2
        WHERE cs2.cs_promo_sk = p.p_promo_sk
          AND cs2.cs_net_profit > 1000
    )
GROUP BY p.p_promo_id, p.p_promo_name, cc.cc_city, cc.cc_state, w.w_street_name
HAVING SUM(cs.cs_net_profit) > (
        SELECT AVG(cs3.cs_net_profit)
        FROM tpcds.catalog_sales cs3
    )
ORDER BY total_profit DESC
LIMIT 100
