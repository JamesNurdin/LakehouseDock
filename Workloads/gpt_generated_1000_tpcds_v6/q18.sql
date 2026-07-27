WITH sales_agg AS (
    SELECT
        cs_call_center_sk,
        cs_promo_sk,
        SUM(cs_net_paid_inc_ship_tax) AS total_net_paid,
        SUM(cs_ext_discount_amt) AS total_discount,
        COUNT(*) AS sales_cnt
    FROM catalog_sales
    WHERE cs_net_paid_inc_ship_tax >= 1000
    GROUP BY cs_call_center_sk, cs_promo_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_name,
    concat(cc.cc_city, ', ', cc.cc_state) AS location,
    cc.cc_gmt_offset,
    p.p_promo_name,
    p.p_channel_press,
    sa.total_net_paid,
    sa.total_discount,
    sa.sales_cnt,
    (
        SELECT AVG(cs_ext_discount_amt)
        FROM catalog_sales cs2
        WHERE cs2.cs_promo_sk = p.p_promo_sk
    ) AS avg_discount_per_promo,
    (
        SELECT COUNT(DISTINCT p2.p_promo_id)
        FROM promotion p2
        JOIN catalog_sales cs3 ON cs3.cs_promo_sk = p2.p_promo_sk
        WHERE cs3.cs_call_center_sk = cc.cc_call_center_sk
    ) AS distinct_promo_cnt
FROM sales_agg sa
JOIN call_center cc
    ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN promotion p
    ON sa.cs_promo_sk = p.p_promo_sk
WHERE
    regexp_like(cc.cc_street_name, '(River|Hill)')
    AND cc.cc_city LIKE 'San%'
    AND substring(cc.cc_zip, 1, 5) = '12345'
    AND p.p_channel_press = 'N'
ORDER BY sa.total_net_paid DESC
LIMIT 100
