WITH excluded_orders AS (
    SELECT cs_order_number
    FROM catalog_sales
    WHERE cs_ext_sales_price > 500
    EXCEPT
    SELECT ss_ticket_number
    FROM store_sales
    WHERE ss_quantity > 5
)
SELECT
    item.i_category,
    promotion.p_promo_name,
    ship_mode.sm_type,
    SUM(store_sales.ss_net_paid) AS total_store_sales,
    SUM(catalog_sales.cs_net_paid) AS total_catalog_sales,
    SUM(store_returns.sr_net_loss) AS total_store_returns_loss,
    SUM(web_returns.wr_net_loss) AS total_web_returns_loss,
    COUNT(DISTINCT store_sales.ss_ticket_number) AS num_transactions,
    AVG(store_sales.ss_quantity) AS avg_quantity
FROM store_sales
JOIN time_dim ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
JOIN item ON store_sales.ss_item_sk = item.i_item_sk
JOIN customer ON store_sales.ss_customer_sk = customer.c_customer_sk
JOIN customer_demographics ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
JOIN household_demographics ON store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
JOIN promotion ON store_sales.ss_promo_sk = promotion.p_promo_sk
JOIN income_band ON household_demographics.hd_income_band_sk = income_band.ib_income_band_sk
JOIN inventory ON item.i_item_sk = inventory.inv_item_sk
JOIN warehouse ON inventory.inv_warehouse_sk = warehouse.w_warehouse_sk
JOIN store_returns ON store_sales.ss_item_sk = store_returns.sr_item_sk
    AND store_sales.ss_ticket_number = store_returns.sr_ticket_number
JOIN reason ON store_returns.sr_reason_sk = reason.r_reason_sk
JOIN web_page ON customer.c_customer_sk = web_page.wp_customer_sk
JOIN web_returns ON item.i_item_sk = web_returns.wr_item_sk
    AND time_dim.t_time_sk = web_returns.wr_returned_time_sk
JOIN catalog_sales ON catalog_sales.cs_sold_time_sk = time_dim.t_time_sk
    AND catalog_sales.cs_item_sk = item.i_item_sk
    AND catalog_sales.cs_bill_customer_sk = customer.c_customer_sk
    AND catalog_sales.cs_promo_sk = promotion.p_promo_sk
JOIN ship_mode ON catalog_sales.cs_ship_mode_sk = ship_mode.sm_ship_mode_sk
WHERE
    item.i_size IN ('medium', 'extra large')
    AND item.i_units = 'Box'
    AND household_demographics.hd_buy_potential = '>10000'
    AND household_demographics.hd_vehicle_count >= 2
    AND customer.c_birth_year = 1975
    AND time_dim.t_hour BETWEEN 9 AND 17
    AND catalog_sales.cs_ext_discount_amt > 10
    AND NOT EXISTS (
        SELECT 1 FROM excluded_orders eo WHERE eo.cs_order_number = store_sales.ss_ticket_number
    )
GROUP BY ROLLUP (item.i_category, promotion.p_promo_name, ship_mode.sm_type)
ORDER BY total_store_sales DESC
LIMIT 100
