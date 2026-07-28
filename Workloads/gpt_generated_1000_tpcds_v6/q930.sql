WITH sales_summary AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_ship_mode_sk,
        cs.cs_promo_sk,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_profit
    FROM catalog_sales cs
)
SELECT
    cc.cc_name                                            AS call_center,
    SUBSTRING(cc.cc_name, 1, 10)                         AS cc_name_short,
    sm.sm_type                                            AS ship_type,
    CONCAT(p.p_promo_name, ' (', p.p_channel_radio, ')') AS promo_desc,
    REGEXP_EXTRACT(p.p_promo_name, '\\d+', 0)          AS promo_number,
    SUM(CASE WHEN sm.sm_code = 'AIR' THEN s.cs_net_profit ELSE 0 END) AS air_profit,
    SUM(s.cs_net_profit)                                   AS total_profit,
    COUNT(DISTINCT s.cs_order_number)                     AS orders,
    MAX(s.cs_quantity)                                    AS max_quantity,
    CASE
        WHEN REGEXP_LIKE(p.p_promo_name, '^.*Clearance.*$') THEN 'Clearance'
        WHEN REGEXP_LIKE(p.p_promo_name, '^.*Holiday.*$')   THEN 'Holiday'
        ELSE 'Other'
    END                                                   AS promo_category
FROM sales_summary s
JOIN call_center cc ON s.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode   sm ON s.cs_ship_mode_sk   = sm.sm_ship_mode_sk
JOIN promotion   p  ON s.cs_promo_sk      = p.p_promo_sk
WHERE
    cc.cc_name LIKE '%Center%'
    AND sm.sm_type LIKE 'REG%'
    AND EXISTS (
        SELECT 1
        FROM catalog_returns cr
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        WHERE cr.cr_order_number = s.cs_order_number
          AND REGEXP_LIKE(r.r_reason_desc, '(?i)damage')
    )
GROUP BY
    cc.cc_name,
    SUBSTRING(cc.cc_name, 1, 10),
    sm.sm_type,
    p.p_promo_name,
    p.p_channel_radio,
    REGEXP_EXTRACT(p.p_promo_name, '\\d+', 0),
    CASE
        WHEN REGEXP_LIKE(p.p_promo_name, '^.*Clearance.*$') THEN 'Clearance'
        WHEN REGEXP_LIKE(p.p_promo_name, '^.*Holiday.*$')   THEN 'Holiday'
        ELSE 'Other'
    END
HAVING
    SUM(s.cs_net_profit) > 10000
ORDER BY
    total_profit DESC
LIMIT 100
