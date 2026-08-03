WITH sampled_sales AS (
    SELECT
        cs_order_number,
        cs_net_paid_inc_ship,
        cs_quantity,
        cs_ext_discount_amt,
        cs_ext_wholesale_cost,
        cs_ext_ship_cost,
        cs_promo_sk
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),
joined_data AS (
    SELECT
        s.cs_order_number,
        s.cs_net_paid_inc_ship,
        s.cs_quantity,
        s.cs_ext_discount_amt,
        s.cs_ext_wholesale_cost,
        s.cs_ext_ship_cost,
        s.cs_promo_sk,
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_dmail,
        CASE WHEN s.cs_ext_ship_cost > 1000 THEN 'HIGH' ELSE 'LOW' END AS ship_cost_category,
        split(p.p_promo_name, ' ') AS promo_name_words
    FROM sampled_sales s
    JOIN promotion p
      ON s.cs_promo_sk = p.p_promo_sk
    WHERE s.cs_net_paid_inc_ship > 5000
      AND s.cs_quantity BETWEEN 1 AND 5
      AND p.p_channel_dmail = 'Y'
      AND p.p_promo_name LIKE '%Holiday%'
),
unnested AS (
    SELECT
        jd.cs_order_number,
        jd.cs_net_paid_inc_ship,
        jd.cs_quantity,
        jd.cs_ext_discount_amt,
        jd.cs_ext_wholesale_cost,
        jd.cs_ext_ship_cost,
        jd.p_promo_id,
        jd.ship_cost_category,
        w.value AS promo_word
    FROM joined_data jd
    CROSS JOIN UNNEST(jd.promo_name_words) AS w (value)
),
aggregated AS (
    SELECT
        p_promo_id,
        ship_cost_category,
        promo_word,
        COUNT(DISTINCT cs_order_number) AS orders_cnt,
        SUM(cs_net_paid_inc_ship) AS total_net_paid,
        AVG(cs_ext_discount_amt) AS avg_discount,
        MIN(cs_ext_wholesale_cost) AS min_wholesale,
        MAX(cs_ext_ship_cost) AS max_ship_cost,
        SUM(CASE WHEN cs_ext_discount_amt > 100 THEN cs_ext_discount_amt ELSE 0 END) AS high_discount_sum
    FROM unnested
    GROUP BY p_promo_id, ship_cost_category, promo_word
)
SELECT *
FROM (
    SELECT
        p_promo_id,
        ship_cost_category,
        promo_word,
        orders_cnt,
        total_net_paid,
        avg_discount,
        min_wholesale,
        max_ship_cost,
        high_discount_sum
    FROM aggregated
) 
EXCEPT
SELECT *
FROM (
    SELECT
        p_promo_id,
        ship_cost_category,
        promo_word,
        orders_cnt,
        total_net_paid,
        avg_discount,
        min_wholesale,
        max_ship_cost,
        high_discount_sum
    FROM aggregated
    WHERE ship_cost_category = 'LOW' AND avg_discount < 5
)
ORDER BY total_net_paid DESC
LIMIT 100
