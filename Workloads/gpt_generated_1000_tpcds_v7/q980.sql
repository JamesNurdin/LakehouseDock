WITH tv_sales AS (
    SELECT
        cc.cc_name AS call_center_name,
        sm.sm_type AS ship_mode_type,
        'TV' AS promo_channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE p.p_channel_tv = 'Y'
    GROUP BY cc.cc_name, sm.sm_type
),
email_sales AS (
    SELECT
        cc.cc_name AS call_center_name,
        sm.sm_type AS ship_mode_type,
        'Email' AS promo_channel,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        SUM(cs.cs_quantity) AS total_quantity
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE p.p_channel_email = 'Y'
    GROUP BY cc.cc_name, sm.sm_type
)
SELECT * FROM tv_sales
UNION ALL
SELECT * FROM email_sales
