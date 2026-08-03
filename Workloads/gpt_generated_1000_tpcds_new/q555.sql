WITH sampled_items AS (
    SELECT *
    FROM item
    TABLESAMPLE BERNOULLI (10)
),
intersect_items AS (
    SELECT cs.cs_item_sk
    FROM catalog_sales cs
    WHERE cs.cs_ext_ship_cost > 500
    INTERSECT
    SELECT sr.sr_item_sk
    FROM store_returns sr
    WHERE sr.sr_return_ship_cost < 100
)
SELECT
    i.i_category,
    s.s_state,
    sm.sm_type,
    p.p_channel_tv,
    SUM(cs.cs_ext_sales_price) AS total_catalog_sales,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(cs.cs_net_profit) AS avg_catalog_profit,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    ROW_NUMBER() OVER (ORDER BY SUM(cs.cs_ext_sales_price) DESC) AS rn
FROM catalog_sales cs
JOIN intersect_items ii ON cs.cs_item_sk = ii.cs_item_sk
JOIN sampled_items i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
JOIN store s ON ss.ss_store_sk = s.s_store_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_item_sk = ss.ss_item_sk
    AND sr.sr_store_sk = s.s_store_sk
WHERE
    i.i_class_id IN (5, 9, 14)
    AND p.p_discount_active = 'Y'
    AND sm.sm_type = 'AIR'
    AND s.s_state = 'CA'
    AND ss.ss_quantity >= 2
GROUP BY CUBE(i.i_category, s.s_state, sm.sm_type, p.p_channel_tv)
ORDER BY total_catalog_sales DESC
LIMIT 100
