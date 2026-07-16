WITH promo_agg AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        i.i_brand,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS promo_sales_revenue,
        SUM(ss.ss_ext_discount_amt) AS total_discount_given,
        p.p_cost,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS promo_inventory_stock
    FROM promotion p
    JOIN store_sales ss ON ss.ss_promo_sk = p.p_promo_sk
    JOIN item i ON p.p_item_sk = i.i_item_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    GROUP BY p.p_promo_id, p.p_promo_name, i.i_brand, i.i_category, p.p_cost
    HAVING SUM(ss.ss_ext_sales_price) > 0
)
SELECT
    p_promo_id,
    p_promo_name,
    i_brand,
    i_category,
    promo_sales_revenue,
    total_discount_given,
    p_cost,
    CASE WHEN p_cost = 0 THEN NULL ELSE (promo_sales_revenue - total_discount_given) / p_cost END AS roi,
    DENSE_RANK() OVER (ORDER BY CASE WHEN p_cost = 0 THEN 0 ELSE (promo_sales_revenue - total_discount_given) / p_cost END DESC) AS roi_rank,
    promo_inventory_stock
FROM promo_agg
ORDER BY roi DESC
LIMIT 15
