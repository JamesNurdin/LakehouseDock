WITH
store_join AS (
    SELECT
        i.i_item_id                     AS item_id,
        i.i_product_name                AS product_name,
        ca.ca_state                     AS state,
        hd.hd_vehicle_count            AS vehicle_count,
        ib.ib_lower_bound               AS income_lower,
        td.t_sub_shift                  AS sub_shift,
        p.p_channel_event               AS channel_event,
        w.w_warehouse_name              AS warehouse_name,
        CAST(NULL AS varchar)           AS sm_type,
        ss.ss_net_paid                  AS net_paid,
        ss.ss_quantity                  AS quantity
    FROM store_sales ss
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        hd.hd_vehicle_count >= 1
        AND hd.hd_dep_count <= 5
        AND td.t_sub_shift = 'morning'
        AND p.p_channel_event = 'N'
        AND w.w_warehouse_sq_ft > 50000
),
web_join AS (
    SELECT
        i.i_item_id                     AS item_id,
        i.i_product_name                AS product_name,
        ca.ca_state                     AS state,
        hd.hd_vehicle_count            AS vehicle_count,
        ib.ib_lower_bound               AS income_lower,
        td.t_sub_shift                  AS sub_shift,
        p.p_channel_event               AS channel_event,
        w.w_warehouse_name              AS warehouse_name,
        sm.sm_type                      AS sm_type,
        ws.ws_net_paid                  AS net_paid,
        ws.ws_quantity                  AS quantity
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ws.ws_ship_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        hd.hd_vehicle_count >= 1
        AND hd.hd_dep_count <= 5
        AND td.t_sub_shift = 'morning'
        AND p.p_channel_event = 'N'
        AND w.w_warehouse_sq_ft > 50000
)
SELECT
    item_id,
    product_name,
    state,
    vehicle_count,
    income_lower,
    sub_shift,
    channel_event,
    warehouse_name,
    sm_type,
    SUM(net_paid)   AS total_net_paid,
    SUM(quantity)   AS total_quantity,
    RANK() OVER (PARTITION BY state ORDER BY SUM(net_paid) DESC) AS state_rank
FROM (
    SELECT * FROM store_join
    UNION ALL
    SELECT * FROM web_join
) s
GROUP BY
    item_id,
    product_name,
    state,
    vehicle_count,
    income_lower,
    sub_shift,
    channel_event,
    warehouse_name,
    sm_type
ORDER BY total_net_paid DESC
LIMIT 100
