WITH item_sales_agg AS (
    SELECT
        i.i_item_id,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        SUM(ss.ss_ext_sales_price) AS total_sales_revenue,
        SUM(ss.ss_quantity) AS total_units_sold,
        COALESCE(SUM(inv.inv_quantity_on_hand), 0) AS total_inventory_on_hand,
        COUNT(DISTINCT p.p_promo_id) AS promo_count
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    GROUP BY i.i_item_id, i.i_product_name, i.i_brand, i.i_category
)
SELECT
    i_item_id,
    i_product_name,
    i_brand,
    i_category,
    total_sales_revenue,
    total_units_sold,
    total_inventory_on_hand,
    promo_count,
    RANK() OVER (ORDER BY total_sales_revenue DESC) AS sales_rank
FROM item_sales_agg
ORDER BY total_sales_revenue DESC
LIMIT 10
