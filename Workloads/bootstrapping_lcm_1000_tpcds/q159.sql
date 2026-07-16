SELECT
    cs.cs_order_number,
    cs.cs_net_paid,
    cs.cs_quantity,
    d_sold.d_date AS sold_date,
    d_ship.d_date AS ship_date,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    p.p_promo_name,
    p.p_discount_active,
    d_start.d_date AS promo_start_date,
    d_end.d_date AS promo_end_date,
    s.s_store_name,
    s.s_city,
    s.s_state,
    d_store.d_date AS store_closed_date,
    CASE
        WHEN cs.cs_net_paid > cs.cs_ext_sales_price * 0.9 THEN 'High'
        ELSE 'Normal'
    END AS payment_category,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY cs.cs_net_paid DESC) AS rn_store_sales
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN item i ON cs.cs_item_sk = i.i_item_sk
JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    AND p.p_item_sk = i.i_item_sk
JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
CROSS JOIN store s
JOIN date_dim d_store ON s.s_closed_date_sk = d_store.d_date_sk
WHERE d_sold.d_year = 2022
  AND s.s_state = 'CA'
  AND i.i_category = 'Electronics'
  AND p.p_discount_active = 'Y'
ORDER BY cs.cs_net_paid DESC
LIMIT 100
