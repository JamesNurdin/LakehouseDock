WITH manager_union AS (
    SELECT s_store_sk FROM store WHERE s_manager = 'Leroy Walker'
    UNION
    SELECT s_store_sk FROM store WHERE s_manager = 'Wayne Coleman'
),
avg_brand_price AS (
    SELECT AVG(i_current_price) AS avg_price FROM item WHERE i_brand = 'BrandX'
)
SELECT
    store.s_store_name,
    COUNT(DISTINCT web_sales.ws_order_number) AS order_cnt,
    SUM(web_sales.ws_net_paid) AS total_net_paid,
    AVG(catalog_returns.cr_return_amount) AS avg_return_amount,
    MIN(inventory.inv_quantity_on_hand) AS min_inventory_qty,
    (SELECT avg_price FROM avg_brand_price) AS avg_brand_price
FROM catalog_page
JOIN catalog_returns
    ON catalog_returns.cr_catalog_page_sk = catalog_page.cp_catalog_page_sk
JOIN customer
    ON catalog_returns.cr_returning_customer_sk = customer.c_customer_sk
JOIN household_demographics
    ON catalog_returns.cr_returning_hdemo_sk = household_demographics.hd_demo_sk
JOIN item
    ON catalog_returns.cr_item_sk = item.i_item_sk
JOIN promotion
    ON promotion.p_item_sk = item.i_item_sk
JOIN inventory
    ON inventory.inv_item_sk = item.i_item_sk
JOIN ship_mode
    ON catalog_returns.cr_ship_mode_sk = ship_mode.sm_ship_mode_sk
JOIN store_returns
    ON store_returns.sr_item_sk = item.i_item_sk
JOIN store
    ON store_returns.sr_store_sk = store.s_store_sk
JOIN web_sales
    ON web_sales.ws_item_sk = item.i_item_sk
JOIN web_site
    ON web_sales.ws_web_site_sk = web_site.web_site_sk
WHERE
    store.s_manager = 'Leroy Walker'
    AND household_demographics.hd_income_band_sk = 18
    AND promotion.p_discount_active = 'Y'
    AND NOT EXISTS (
        SELECT 1 FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = item.i_item_sk
          AND cr2.cr_return_amount > 200
    )
    AND NOT EXISTS (
        SELECT 1 FROM manager_union mu
        WHERE mu.s_store_sk = store.s_store_sk
    )
GROUP BY
    store.s_store_name
LIMIT 100
