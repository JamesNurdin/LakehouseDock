WITH combined AS (
    SELECT
        p.p_promo_name,
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship,
        cs.cs_quantity,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY cs.cs_net_paid_inc_ship DESC) AS rn
    FROM
        catalog_sales cs
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        cs.cs_net_paid_inc_ship > 5000
        AND p.p_channel_tv = 'Y'
    UNION ALL
    SELECT
        p.p_promo_name,
        cs.cs_order_number,
        cs.cs_net_paid_inc_ship,
        cs.cs_quantity,
        ROW_NUMBER() OVER (PARTITION BY p.p_promo_name ORDER BY cs.cs_net_paid_inc_ship DESC) AS rn
    FROM
        catalog_sales cs
        JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE
        cs.cs_quantity >= 10
        AND p.p_discount_active = 'Y'
)
SELECT
    p_promo_name,
    cs_order_number,
    cs_net_paid_inc_ship,
    cs_quantity,
    rn
FROM
    combined
ORDER BY
    cs_net_paid_inc_ship DESC
LIMIT 100
