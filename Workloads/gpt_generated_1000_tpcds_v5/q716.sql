WITH sales_agg AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_order_number,
        cs.cs_promo_sk,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE regexp_like(cc.cc_name, '^.*Center$')
      AND cp.cp_description LIKE '%special%'
    GROUP BY cs.cs_call_center_sk, cs.cs_catalog_page_sk, cs.cs_order_number, cs.cs_promo_sk
)
SELECT
    cc.cc_name,
    cp.cp_description,
    CONCAT(cc.cc_city, ', ', cc.cc_state) AS location,
    SUBSTRING(cc.cc_name FROM 1 FOR 5) AS name_prefix,
    REGEXP_EXTRACT(cp.cp_description, '(\\w+)', 1) AS first_word_desc,
    p.p_promo_name,
    sa.total_net_paid,
    sa.total_profit,
    (
        SELECT MAX(p2.p_cost)
        FROM promotion p2
        WHERE p2.p_promo_id = p.p_promo_id
    ) AS max_promo_cost
FROM sales_agg sa
JOIN call_center cc ON sa.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON sa.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN promotion p ON sa.cs_promo_sk = p.p_promo_sk
WHERE EXISTS (
    SELECT 1
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_order_number = sa.cs_order_number
      AND REGEXP_LIKE(r.r_reason_desc, '.*return.*')
)
ORDER BY sa.total_profit DESC
LIMIT 100
