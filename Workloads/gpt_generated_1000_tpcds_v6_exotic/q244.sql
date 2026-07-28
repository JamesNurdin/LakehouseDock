WITH distinct_web AS (
    SELECT DISTINCT wp_customer_sk, wp_url
    FROM web_page
),

returns_data AS (
    SELECT
        store.s_store_name AS store_name,
        d_ret.d_year AS year,
        SUM(store_returns.sr_return_amt) AS total_return_amt,
        0 AS total_inventory_qty,
        0 AS total_promo_cost,
        COUNT(DISTINCT store_returns.sr_ticket_number) AS distinct_ticket_cnt,
        CASE WHEN household_demographics.hd_vehicle_count >= 2 THEN 'MultiVehicle' ELSE 'LowVehicle' END AS vehicle_category
    FROM store_returns
    JOIN date_dim d_ret
        ON store_returns.sr_returned_date_sk = d_ret.d_date_sk
    JOIN store
        ON store_returns.sr_store_sk = store.s_store_sk
    JOIN item
        ON store_returns.sr_item_sk = item.i_item_sk
    JOIN customer
        ON store_returns.sr_customer_sk = customer.c_customer_sk
    JOIN household_demographics
        ON store_returns.sr_hdemo_sk = household_demographics.hd_demo_sk
    JOIN catalog_page
        ON catalog_page.cp_start_date_sk = d_ret.d_date_sk
    JOIN distinct_web dw
        ON dw.wp_customer_sk = customer.c_customer_sk
    JOIN web_page
        ON web_page.wp_customer_sk = customer.c_customer_sk
        AND web_page.wp_creation_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2002
      AND store.s_county = 'Mesa County'
      AND household_demographics.hd_vehicle_count >= 2
      AND catalog_page.cp_catalog_number = 12
      AND web_page.wp_type = 'Content'
    GROUP BY
        store.s_store_name,
        d_ret.d_year,
        CASE WHEN household_demographics.hd_vehicle_count >= 2 THEN 'MultiVehicle' ELSE 'LowVehicle' END
),

inventory_promo_data AS (
    SELECT
        store.s_store_name AS store_name,
        d_inv.d_year AS year,
        0 AS total_return_amt,
        SUM(inventory.inv_quantity_on_hand) AS total_inventory_qty,
        SUM(promotion.p_cost) AS total_promo_cost,
        0 AS distinct_ticket_cnt,
        CASE WHEN household_demographics.hd_vehicle_count >= 2 THEN 'MultiVehicle' ELSE 'LowVehicle' END AS vehicle_category
    FROM inventory
    JOIN date_dim d_inv
        ON inventory.inv_date_sk = d_inv.d_date_sk
    JOIN item
        ON inventory.inv_item_sk = item.i_item_sk
    JOIN warehouse
        ON inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
    JOIN store_returns
        ON store_returns.sr_item_sk = item.i_item_sk
        AND store_returns.sr_returned_date_sk = d_inv.d_date_sk
    JOIN store
        ON store_returns.sr_store_sk = store.s_store_sk
    JOIN household_demographics
        ON store_returns.sr_hdemo_sk = household_demographics.hd_demo_sk
    JOIN promotion
        ON promotion.p_item_sk = item.i_item_sk
    JOIN date_dim d_promo_start
        ON promotion.p_start_date_sk = d_promo_start.d_date_sk
    WHERE d_inv.d_year = 2002
      AND warehouse.w_state = 'TX'
      AND item.i_category = 'Electronics'
      AND promotion.p_discount_active = 'Y'
      AND inventory.inv_quantity_on_hand > 0
    GROUP BY
        store.s_store_name,
        d_inv.d_year,
        CASE WHEN household_demographics.hd_vehicle_count >= 2 THEN 'MultiVehicle' ELSE 'LowVehicle' END
)

SELECT *
FROM (
    SELECT * FROM returns_data
    UNION ALL
    SELECT * FROM inventory_promo_data
) AS combined
ORDER BY store_name, year
LIMIT 100
