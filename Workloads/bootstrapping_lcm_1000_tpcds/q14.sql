WITH combined AS (
    SELECT
        inv.inv_item_sk,
        inv.inv_quantity_on_hand,
        d_common.d_date AS start_date,
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        cp.cp_catalog_page_number,
        cp.cp_catalog_page_id,
        cp.cp_description,
        p.p_promo_name,
        p.p_cost,
        d_cp_end.d_date AS cp_end_date,
        d_promo_end.d_date AS promo_end_date
    FROM inventory inv
    JOIN date_dim d_common
        ON inv.inv_date_sk = d_common.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_common.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_common.d_date_sk
    JOIN date_dim d_cp_end
        ON cp.cp_end_date_sk = d_cp_end.d_date_sk
    JOIN promotion p
        ON p.p_start_date_sk = d_common.d_date_sk
    JOIN date_dim d_promo_end
        ON p.p_end_date_sk = d_promo_end.d_date_sk
),
aggregated AS (
    SELECT
        s_store_id AS store_id,
        s_store_name AS store_name,
        s_city AS store_city,
        cp_catalog_page_number,
        cp_catalog_page_id,
        cp_description,
        p_promo_name,
        SUM(inv_quantity_on_hand) AS total_quantity_on_hand,
        AVG(p_cost) AS avg_promo_cost,
        MIN(cp_end_date) AS cp_end_date,
        MIN(promo_end_date) AS promo_end_date,
        DATE_DIFF('day', MIN(start_date), MIN(cp_end_date)) AS catalog_page_duration_days,
        DATE_DIFF('day', MIN(start_date), MIN(promo_end_date)) AS promo_duration_days
    FROM combined
    WHERE start_date >= DATE '2022-01-01' AND start_date < DATE '2023-01-01'
    GROUP BY
        s_store_id,
        s_store_name,
        s_city,
        cp_catalog_page_number,
        cp_catalog_page_id,
        cp_description,
        p_promo_name
)
SELECT
    store_id,
    store_name,
    store_city,
    cp_catalog_page_number,
    cp_catalog_page_id,
    cp_description,
    p_promo_name,
    total_quantity_on_hand,
    avg_promo_cost,
    cp_end_date,
    promo_end_date,
    catalog_page_duration_days,
    promo_duration_days,
    RANK() OVER (PARTITION BY store_id ORDER BY total_quantity_on_hand DESC) AS inventory_quantity_rank_per_store
FROM aggregated
ORDER BY total_quantity_on_hand DESC
LIMIT 200
