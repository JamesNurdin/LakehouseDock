WITH joined AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_wholesale_cost,
        cs.cs_coupon_amt,
        cs.cs_ext_sales_price,
        cs.cs_quantity,
        ss.ss_ext_sales_price,
        ss.ss_quantity,
        t.t_shift,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        s.s_floor_space,
        i.i_color,
        p.p_discount_active,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN store_sales ss
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
        AND ss.ss_item_sk = i.i_item_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
        AND ss.ss_promo_sk = p.p_promo_sk
        AND p.p_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    WHERE cs.cs_wholesale_cost > 30.00
      AND cs.cs_coupon_amt > 500.00
      AND t.t_shift = 'first'
      AND s.s_floor_space > 7000000
      AND i.i_color = 'Red'
      AND p.p_discount_active = 'Y'
      AND inv.inv_quantity_on_hand > 0
),
agg AS (
    SELECT
        s_store_id AS store_id,
        s_store_name AS store_name,
        s_state AS state,
        cs_sold_date_sk AS sold_date_sk,
        SUM(cs_ext_sales_price + ss_ext_sales_price) AS total_sales,
        SUM(cs_quantity + ss_quantity) AS total_quantity,
        (SELECT AVG(cs2.cs_ext_sales_price)
         FROM catalog_sales cs2
         WHERE cs2.cs_sold_date_sk = cs_sold_date_sk) AS avg_catalog_price_for_date
    FROM joined
    GROUP BY s_store_id, s_store_name, s_state, cs_sold_date_sk
)
SELECT
    store_id,
    store_name,
    state,
    sold_date_sk,
    total_sales,
    total_quantity,
    avg_catalog_price_for_date,
    ROW_NUMBER() OVER (PARTITION BY sold_date_sk ORDER BY total_sales DESC) AS sales_rank
FROM agg
ORDER BY sold_date_sk, sales_rank
LIMIT 100
