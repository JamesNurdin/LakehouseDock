SELECT
    cp.cp_catalog_page_id,
    cp.cp_catalog_page_number,
    cp.cp_description,
    d_start.d_year AS start_year,
    d_start.d_month_seq AS start_month,
    d_end.d_year AS end_year,
    d_end.d_month_seq AS end_month,
    p.p_promo_name,
    p.p_discount_active,
    p.p_cost,
    d_promo_end.d_year AS promo_end_year,
    s.s_store_name,
    s.s_state,
    s.s_market_desc,
    i.inv_warehouse_sk,
    i.inv_quantity_on_hand,
    SUM(i.inv_quantity_on_hand) OVER (
        PARTITION BY cp.cp_catalog_page_id
        ORDER BY i.inv_quantity_on_hand DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_qty,
    ROW_NUMBER() OVER (
        PARTITION BY cp.cp_catalog_page_id
        ORDER BY i.inv_quantity_on_hand DESC
    ) AS rank_qty
FROM catalog_page cp
JOIN date_dim d_start ON cp.cp_start_date_sk = d_start.d_date_sk
JOIN date_dim d_end ON cp.cp_end_date_sk = d_end.d_date_sk
JOIN promotion p ON p.p_start_date_sk = d_start.d_date_sk
JOIN date_dim d_promo_end ON p.p_end_date_sk = d_promo_end.d_date_sk
JOIN inventory i ON i.inv_date_sk = d_start.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_end.d_date_sk
WHERE cp.cp_type = 'Catalog'
  AND p.p_discount_active = 'Y'
  AND i.inv_quantity_on_hand > 0
ORDER BY cp.cp_catalog_page_number DESC, rank_qty
LIMIT 100
