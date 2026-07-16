WITH promo_inv AS (
    SELECT
        cp.cp_type,
        p.p_channel_tv,
        p.p_channel_email,
        COUNT(DISTINCT p.p_item_sk) AS distinct_item_cnt,
        SUM(p.p_cost) AS total_promo_cost,
        AVG(i.inv_quantity_on_hand) AS avg_inventory_qty,
        SUM(p.p_response_target) AS total_response_target
    FROM
        promotion p
    JOIN
        inventory i
        ON p.p_item_sk = i.inv_item_sk
    JOIN
        catalog_page cp
        ON p.p_start_date_sk <= cp.cp_end_date_sk
       AND p.p_end_date_sk >= cp.cp_start_date_sk
    WHERE
        cp.cp_type IN ('monthly', 'quarterly')
        AND p.p_discount_active = 'Y'
        AND i.inv_quantity_on_hand > 0
        AND EXISTS (
            SELECT 1 FROM household_demographics hd
            WHERE hd.hd_vehicle_count >= 2
              AND hd.hd_buy_potential = 'high'
        )
        AND EXISTS (
            SELECT 1 FROM customer_address ca
            WHERE ca.ca_country = 'United States'
              AND ca.ca_gmt_offset BETWEEN -5.00 AND -4.00
        )
    GROUP BY
        cp.cp_type,
        p.p_channel_tv,
        p.p_channel_email
    HAVING
        SUM(p.p_cost) > 1000
)
SELECT
    cp_type,
    p_channel_tv,
    p_channel_email,
    distinct_item_cnt,
    total_promo_cost,
    avg_inventory_qty,
    total_response_target,
    RANK() OVER (ORDER BY total_promo_cost DESC) AS promo_cost_rank
FROM
    promo_inv
ORDER BY
    total_promo_cost DESC
LIMIT 50
