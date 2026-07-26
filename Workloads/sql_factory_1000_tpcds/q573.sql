WITH cs_detail AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_quantity,
        cs.cs_ext_discount_amt,
        cs.cs_ext_list_price,
        t.t_hour,
        p.p_promo_name,
        p.p_discount_active,
        cs.cs_net_profit
    FROM catalog_sales cs
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_quantity > 5
)
SELECT
    cs_item_sk,
    cs_promo_sk,
    p_promo_name,
    t_hour,
    SUM(cs_ext_discount_amt) AS total_discount_amt,
    AVG(cs_ext_discount_amt / NULLIF(cs_ext_list_price,0)) AS avg_discount_ratio,
    ROW_NUMBER() OVER (PARTITION BY t_hour ORDER BY SUM(cs_ext_discount_amt) DESC) AS discount_rank_in_hour,
    CASE
        WHEN p_discount_active = 'Y' AND AVG(cs_ext_discount_amt / NULLIF(cs_ext_list_price,0)) > 0.25 THEN 'HIGH_DISCOUNT_ACTIVE'
        WHEN p_discount_active = 'Y' THEN 'DISCOUNT_ACTIVE'
        ELSE 'NO_DISCOUNT'
    END AS discount_status
FROM cs_detail
GROUP BY cs_item_sk, cs_promo_sk, p_promo_name, t_hour, p_discount_active
HAVING SUM(cs_ext_discount_amt) > 1000
ORDER BY t_hour, discount_rank_in_hour
