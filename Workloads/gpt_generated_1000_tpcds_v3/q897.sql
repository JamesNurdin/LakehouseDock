WITH filtered_sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_sold_time_sk,
        cs.cs_call_center_sk,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_order_number,
        i.i_item_id,
        i.i_item_desc,
        p.p_promo_name,
        sm.sm_type,
        t.t_shift,
        t.t_sub_shift,
        regexp_extract(i.i_item_desc, '(\\d{3})', 1) AS item_code
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE
        t.t_shift = 'second'
        AND t.t_sub_shift LIKE 'even%'
        AND regexp_like(i.i_item_desc, '\\d{3}')
        AND p.p_promo_name LIKE '%DISCOUNT%'
        AND sm.sm_type = 'EXPRESS'
)
SELECT
    i_item_id,
    i_item_desc,
    p_promo_name,
    sm_type,
    t_shift,
    t_sub_shift,
    item_code,
    CONCAT(i_item_desc, ' - ', p_promo_name) AS item_promo_label,
    SUM(cs_net_paid) AS total_sales,
    SUM(cs_net_profit) AS total_profit,
    COUNT(DISTINCT cs_order_number) AS order_count
FROM filtered_sales
GROUP BY
    i_item_id,
    i_item_desc,
    p_promo_name,
    sm_type,
    t_shift,
    t_sub_shift,
    item_code
ORDER BY total_sales DESC
LIMIT 100
