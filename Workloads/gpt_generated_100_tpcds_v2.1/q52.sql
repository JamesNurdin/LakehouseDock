WITH sales_promo AS (
    SELECT
        cs.cs_ship_mode_sk,
        cs.cs_sold_time_sk,
        cs.cs_promo_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_order_number
    FROM catalog_sales cs
    WHERE cs.cs_ext_sales_price > 1000
),
promotion_filtered AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        p.p_cost,
        p.p_channel_radio
    FROM promotion p
    WHERE REGEXP_LIKE(p.p_promo_name, '(?i)summer|holiday')
      AND p.p_channel_radio = 'Y'
)
SELECT
    sm.sm_carrier,
    td.t_meal_time,
    COUNT(DISTINCT sp.cs_order_number) AS order_cnt,
    SUM(sp.cs_ext_sales_price) AS total_sales,
    AVG(sp.cs_net_profit) AS avg_profit,
    REGEXP_EXTRACT(pf.p_promo_id, '(\\d+)', 1) AS promo_id_num,
    CONCAT(sm.sm_carrier, '-', td.t_meal_time) AS carrier_meal,
    (SELECT avg(p_cost) FROM promotion) AS avg_promo_cost
FROM sales_promo sp
JOIN promotion_filtered pf ON sp.cs_promo_sk = pf.p_promo_sk
JOIN ship_mode sm ON sp.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN time_dim td ON sp.cs_sold_time_sk = td.t_time_sk
WHERE td.t_meal_time LIKE 'dinner%'
  AND SUBSTRING(sm.sm_carrier, 1, 3) = 'UPS'
GROUP BY sm.sm_carrier, td.t_meal_time, pf.p_promo_id
ORDER BY total_sales DESC
LIMIT 100
