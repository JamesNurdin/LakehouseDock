WITH cs_detail AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_ext_discount_amt,
        cs.cs_ext_list_price,
        t.t_hour,
        p.p_promo_name,
        p.p_discount_active
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
)
SELECT
    cs_item_sk,
    cs_promo_sk,
    p_promo_name,
    t_hour,
    CASE
        WHEN cs_ext_list_price = 0 THEN 0
        ELSE cs_ext_discount_amt / cs_ext_list_price
    END AS discount_ratio,
    DENSE_RANK() OVER (PARTITION BY t_hour ORDER BY CASE WHEN cs_ext_list_price = 0 THEN 0 ELSE cs_ext_discount_amt / cs_ext_list_price END DESC) AS discount_rank_in_hour,
    CASE
        WHEN p_discount_active = 'Y' AND (CASE WHEN cs_ext_list_price = 0 THEN 0 ELSE cs_ext_discount_amt / cs_ext_list_price END) > 0.2 THEN 'HIGH_DISCOUNT_ACTIVE'
        WHEN p_discount_active = 'Y' THEN 'DISCOUNT_ACTIVE'
        ELSE 'NO_DISCOUNT'
    END AS discount_status
FROM cs_detail
WHERE cs_ext_list_price IS NOT NULL
ORDER BY t_hour, discount_rank_in_hour
