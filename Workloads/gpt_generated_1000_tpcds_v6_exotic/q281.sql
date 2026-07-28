WITH enriched_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        i.i_brand,
        i.i_item_desc,
        i.i_item_id,
        p.p_promo_name,
        p.p_channel_email,
        p.p_channel_catalog,
        sm.sm_ship_mode_id,
        w.w_warehouse_name
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE regexp_like(i.i_item_desc, '\\b[A-Z]{3}\\b')
      AND i.i_item_id LIKE 'AA%'
),
aggregated AS (
    SELECT
        i_brand,
        p_channel_email,
        SUM(cs_net_paid) AS total_net_paid,
        SUM(cs_ext_discount_amt) AS total_discount,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(DISTINCT cs_order_number) AS orders
    FROM enriched_sales
    GROUP BY GROUPING SETS (
        (i_brand, p_channel_email),
        (i_brand),
        ()
    )
)
SELECT
    i_brand,
    p_channel_email,
    CASE
        WHEN p_channel_email IS NOT NULL AND regexp_like(p_channel_email, '^A') THEN 'StartsWithA'
        ELSE 'Other'
    END AS email_channel_category,
    CONCAT(i_brand, ':', COALESCE(p_channel_email, 'ALL')) AS brand_email_key,
    total_net_paid,
    total_discount,
    orders,
    CASE
        WHEN total_net_profit > 0 THEN 'Profitable'
        ELSE 'NotProfitable'
    END AS profit_status
FROM aggregated
ORDER BY total_net_paid DESC
LIMIT 100
