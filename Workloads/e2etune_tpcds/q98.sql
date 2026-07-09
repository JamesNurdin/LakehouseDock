WITH promo_demo AS (
    SELECT
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_tv,
        p.p_channel_email,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_item_sk,
        p.p_cost,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT i.inv_warehouse_sk) AS warehouse_cnt
    FROM promotion p
    JOIN household_demographics hd
        ON p.p_promo_sk = hd.hd_demo_sk
    JOIN inventory i
        ON p.p_item_sk = i.inv_item_sk
        AND i.inv_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    GROUP BY
        p.p_promo_id,
        p.p_promo_name,
        p.p_channel_tv,
        p.p_channel_email,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_item_sk,
        p.p_cost,
        hd.hd_buy_potential,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count
),
promo_catalog AS (
    SELECT
        cp.cp_type,
        cp.cp_department,
        cp.cp_catalog_number,
        pd.p_promo_id,
        pd.p_promo_name,
        pd.total_qty,
        pd.p_cost,
        pd.hd_buy_potential,
        pd.hd_vehicle_count,
        ROW_NUMBER() OVER (PARTITION BY cp.cp_type ORDER BY pd.total_qty DESC) AS promo_rank
    FROM promo_demo pd
    JOIN catalog_page cp
        ON pd.p_start_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
        AND pd.p_end_date_sk BETWEEN cp.cp_start_date_sk AND cp.cp_end_date_sk
    WHERE cp.cp_type IN ('monthly', 'quarterly')
)
SELECT
    pc.cp_type,
    pc.cp_department,
    pc.cp_catalog_number,
    pc.p_promo_name,
    pc.total_qty,
    pc.p_cost,
    pc.hd_buy_potential,
    pc.hd_vehicle_count,
    pc.promo_rank,
    ca.city_cnt
FROM promo_catalog pc
CROSS JOIN (
    SELECT COUNT(DISTINCT ca_city) AS city_cnt
    FROM customer_address
    WHERE ca_country = 'United States'
) ca
WHERE pc.promo_rank <= 10
ORDER BY pc.cp_type, pc.promo_rank
