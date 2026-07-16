WITH agg AS (
    SELECT
        d_inv.d_year,
        d_inv.d_month_seq,
        s.s_store_name,
        s.s_state,
        i.i_category,
        i.i_product_name,
        p.p_promo_name,
        d_end.d_date AS promo_end_date,
        SUM(inv.inv_quantity_on_hand) AS total_quantity,
        SUM(inv.inv_quantity_on_hand * i.i_current_price) AS total_sales,
        SUM(inv.inv_quantity_on_hand * p.p_cost) AS total_promo_cost
    FROM inventory inv
    JOIN date_dim d_inv
        ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN item i
        ON inv.inv_item_sk = i.i_item_sk
    JOIN store s
        ON s.s_closed_date_sk = d_inv.d_date_sk
    JOIN promotion p
        ON p.p_item_sk = i.i_item_sk
       AND p.p_start_date_sk = d_inv.d_date_sk
    JOIN date_dim d_end
        ON p.p_end_date_sk = d_end.d_date_sk
    WHERE p.p_discount_active = 'Y'
    GROUP BY
        d_inv.d_year,
        d_inv.d_month_seq,
        s.s_store_name,
        s.s_state,
        i.i_category,
        i.i_product_name,
        p.p_promo_name,
        d_end.d_date
)
SELECT
    agg.d_year,
    agg.d_month_seq,
    agg.s_store_name,
    agg.s_state,
    agg.i_category,
    agg.i_product_name,
    agg.p_promo_name,
    agg.promo_end_date,
    agg.total_quantity,
    agg.total_sales,
    agg.total_promo_cost,
    ROW_NUMBER() OVER (PARTITION BY agg.d_year, agg.s_store_name ORDER BY agg.total_sales DESC) AS sales_rank
FROM agg
ORDER BY agg.d_year, sales_rank
LIMIT 100
