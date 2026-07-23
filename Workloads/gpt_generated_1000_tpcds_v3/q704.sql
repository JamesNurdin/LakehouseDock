WITH joined_data AS (
    SELECT
        s.s_store_sk,
        s.s_store_id,
        s.s_store_name,
        s.s_company_id,
        s.s_geography_class,
        i.i_item_sk,
        i.i_product_name,
        i.i_current_price,
        i.i_category,
        inv.inv_quantity_on_hand,
        d_inv.d_date AS inv_date,
        d_inv.d_year,
        d_start.d_date AS promo_start_date,
        d_end.d_date AS promo_end_date,
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        p.p_channel_catalog,
        CASE WHEN inv.inv_quantity_on_hand > 100 THEN 'HighStock' ELSE 'NormalStock' END AS stock_level,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Discounted' ELSE 'Regular' END AS promo_status
    FROM inventory inv
    JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN item i ON inv.inv_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN date_dim d_start ON p.p_start_date_sk = d_start.d_date_sk
    JOIN date_dim d_end ON p.p_end_date_sk = d_end.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d_inv.d_date_sk
    WHERE s.s_company_id = 1
      AND s.s_geography_class = 'Unknown'
      AND p.p_channel_catalog = 'N'
      AND d_inv.d_holiday = 'N'
      AND i.i_current_price > 20
      AND inv.inv_quantity_on_hand > 0
      AND d_inv.d_year = 2001
)
SELECT
    s_store_id,
    s_store_name,
    i_product_name,
    i_category,
    inv_date,
    inv_quantity_on_hand,
    stock_level,
    promo_status,
    p_promo_name,
    RANK() OVER (PARTITION BY s_store_sk, inv_date ORDER BY inv_quantity_on_hand DESC) AS qty_rank
FROM joined_data
ORDER BY qty_rank, s_store_id
LIMIT 100
