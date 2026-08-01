WITH
    -- sales (order) date dimension (alias for sold date)
    sold_date AS (
        SELECT d_date_sk, d_date, d_year
        FROM date_dim
        WHERE d_year = 2000
    ),
    -- shipping date dimension (separate alias)
    ship_date AS (
        SELECT d_date_sk
        FROM date_dim
        WHERE d_year = 2000
    ),
    -- billing household demographics (alias for bill)
    bill_hdemo AS (
        SELECT hd_demo_sk, hd_buy_potential
        FROM household_demographics
        WHERE hd_income_band_sk BETWEEN 10 AND 20
    ),
    -- shipping household demographics (alias for ship)
    ship_hdemo AS (
        SELECT hd_demo_sk, hd_vehicle_count
        FROM household_demographics
        WHERE hd_income_band_sk BETWEEN 10 AND 20
    ),
    -- billing address (alias for bill)
    bill_addr AS (
        SELECT ca_address_sk, ca_city
        FROM customer_address
        WHERE ca_state = 'CA'
    ),
    -- shipping address (alias for ship)
    ship_addr AS (
        SELECT ca_address_sk, ca_city
        FROM customer_address
        WHERE ca_state = 'CA'
    ),
    -- inventory filtered by quantity on hand
    inventory_sub AS (
        SELECT inv_date_sk, inv_quantity_on_hand
        FROM inventory
        WHERE inv_quantity_on_hand > 100
    ),
    -- web sales fact subset needed for the analysis
    web_sales_sub AS (
        SELECT ws_order_number,
               ws_sold_date_sk,
               ws_sold_time_sk,
               ws_ship_date_sk,
               ws_bill_hdemo_sk,
               ws_ship_hdemo_sk,
               ws_bill_addr_sk,
               ws_ship_addr_sk,
               ws_web_site_sk,
               ws_item_sk,
               ws_quantity,
               ws_net_profit,
               ws_list_price
        FROM web_sales
        WHERE ws_quantity > 0
    ),
    -- intersected order numbers (quantity >5 and profit >2000)
    order_intersect AS (
        SELECT DISTINCT ws_order_number
        FROM web_sales_sub
        WHERE ws_quantity > 5
        INTERSECT
        SELECT DISTINCT ws_order_number
        FROM web_sales_sub
        WHERE ws_net_profit > 2000
    )
SELECT
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    sd.d_date AS sold_date,
    td.t_hour,
    td.t_minute,
    wd.web_name,
    bhd.hd_buy_potential,
    shd.hd_vehicle_count,
    bill_addr.ca_city AS bill_city,
    ship_addr.ca_city AS ship_city,
    COUNT(DISTINCT ws.ws_item_sk) AS distinct_items,
    SUM(ws.ws_net_profit) AS total_net_profit,
    AVG(ws.ws_quantity) AS avg_quantity,
    (
        SELECT MAX(ws_sub.ws_list_price)
        FROM web_sales_sub ws_sub
        WHERE ws_sub.ws_order_number = ws.ws_order_number
          AND ws_sub.ws_list_price IS NOT NULL
    ) AS max_list_price
FROM
    web_sales_sub ws
    JOIN sold_date sd ON ws.ws_sold_date_sk = sd.d_date_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN ship_date shp ON ws.ws_ship_date_sk = shp.d_date_sk
    JOIN web_site wd ON ws.ws_web_site_sk = wd.web_site_sk
    JOIN bill_hdemo bhd ON ws.ws_bill_hdemo_sk = bhd.hd_demo_sk
    JOIN ship_hdemo shd ON ws.ws_ship_hdemo_sk = shd.hd_demo_sk
    JOIN bill_addr ON ws.ws_bill_addr_sk = bill_addr.ca_address_sk
    JOIN ship_addr ON ws.ws_ship_addr_sk = ship_addr.ca_address_sk
    JOIN inventory_sub inv ON inv.inv_date_sk = sd.d_date_sk
WHERE
    ws.ws_order_number IN (SELECT ws_order_number FROM order_intersect)
    AND wd.web_rec_start_date <= DATE '2000-12-31'
    AND wd.web_rec_end_date >= DATE '2000-01-01'
GROUP BY
    ws.ws_order_number,
    ws.ws_sold_date_sk,
    sd.d_date,
    td.t_hour,
    td.t_minute,
    wd.web_name,
    bhd.hd_buy_potential,
    shd.hd_vehicle_count,
    bill_addr.ca_city,
    ship_addr.ca_city
HAVING
    SUM(ws.ws_net_profit) > 1000
ORDER BY
    total_net_profit DESC,
    ws.ws_order_number
LIMIT 100
