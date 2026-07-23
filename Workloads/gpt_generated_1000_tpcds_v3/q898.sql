WITH store_promo AS (
    SELECT
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        p.p_purpose,
        SUM(ss.ss_net_profit) AS total_net_profit,
        (SELECT SUM(p2.p_cost) FROM promotion p2 WHERE p2.p_purpose = p.p_purpose) AS total_purpose_cost,
        'Store' AS sales_type
    FROM store_sales ss
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_education_status = 'College'
      AND p.p_channel_tv = 'Y'
    GROUP BY p.p_promo_id, p.p_promo_name, p.p_purpose
),
catalog_promo AS (
    SELECT
        p.p_promo_id AS promo_id,
        p.p_promo_name AS promo_name,
        p.p_purpose,
        SUM(cs.cs_net_profit) AS total_net_profit,
        (SELECT SUM(p2.p_cost) FROM promotion p2 WHERE p2.p_purpose = p.p_purpose) AS total_purpose_cost,
        'Catalog' AS sales_type
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE p.p_discount_active = 'Y'
      AND cc.cc_division = 1
    GROUP BY p.p_promo_id, p.p_promo_name, p.p_purpose
)
SELECT
    promo_id,
    promo_name,
    total_net_profit,
    total_purpose_cost,
    sales_type
FROM store_promo
UNION ALL
SELECT
    promo_id,
    promo_name,
    total_net_profit,
    total_purpose_cost,
    sales_type
FROM catalog_promo
ORDER BY total_net_profit DESC
