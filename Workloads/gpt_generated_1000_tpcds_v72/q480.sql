WITH cat_agg AS (
    SELECT
        cr_call_center_sk,
        cr_warehouse_sk,
        cr_ship_mode_sk,
        cr_returned_time_sk,
        cr_refunded_customer_sk,
        SUM(cr_net_loss) AS cat_net_loss,
        COUNT(*) AS cat_return_cnt
    FROM catalog_returns
    GROUP BY cr_call_center_sk, cr_warehouse_sk, cr_ship_mode_sk, cr_returned_time_sk, cr_refunded_customer_sk
),
store_agg AS (
    SELECT
        sr_return_time_sk,
        sr_customer_sk,
        SUM(sr_net_loss) AS store_net_loss,
        COUNT(*) AS store_return_cnt
    FROM store_returns
    GROUP BY sr_return_time_sk, sr_customer_sk
)
SELECT
    call_center.cc_name,
    warehouse.w_city,
    household_demographics.hd_buy_potential,
    time_dim.t_hour,
    SUM(cat_agg.cat_net_loss) AS total_catalog_net_loss,
    SUM(store_agg.store_net_loss) AS total_store_net_loss,
    COUNT(DISTINCT customer.c_customer_sk) AS distinct_customers,
    AVG(web_page.wp_char_count) AS avg_web_page_chars,
    SUM(inventory.inv_quantity_on_hand) AS total_inventory_qty,
    MIN(inventory.inv_quantity_on_hand) AS min_inventory_qty,
    MAX(inventory.inv_quantity_on_hand) AS max_inventory_qty
FROM cat_agg
JOIN call_center
    ON cat_agg.cr_call_center_sk = call_center.cc_call_center_sk
JOIN warehouse
    ON cat_agg.cr_warehouse_sk = warehouse.w_warehouse_sk
JOIN ship_mode
    ON cat_agg.cr_ship_mode_sk = ship_mode.sm_ship_mode_sk
JOIN time_dim
    ON cat_agg.cr_returned_time_sk = time_dim.t_time_sk
JOIN customer
    ON cat_agg.cr_refunded_customer_sk = customer.c_customer_sk
JOIN store_agg
    ON store_agg.sr_customer_sk = customer.c_customer_sk
    AND store_agg.sr_return_time_sk = time_dim.t_time_sk
JOIN household_demographics
    ON customer.c_current_hdemo_sk = household_demographics.hd_demo_sk
JOIN customer_address
    ON customer.c_current_addr_sk = customer_address.ca_address_sk
JOIN inventory
    ON inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
JOIN web_page
    ON web_page.wp_customer_sk = customer.c_customer_sk
WHERE
    call_center.cc_state = 'CA'
    AND web_page.wp_rec_start_date >= DATE '2000-01-01'
    AND web_page.wp_rec_end_date <= DATE '2001-12-31'
    AND warehouse.w_gmt_offset = -5.00
    AND time_dim.t_hour BETWEEN 9 AND 17
    AND customer_address.ca_city = 'Lincoln'
    AND inventory.inv_quantity_on_hand > 100
GROUP BY
    call_center.cc_name,
    warehouse.w_city,
    household_demographics.hd_buy_potential,
    time_dim.t_hour
ORDER BY
    total_catalog_net_loss DESC,
    total_store_net_loss DESC
