WITH inventory_agg AS (
    SELECT
        inv_item_sk,
        SUM(inv_quantity_on_hand) AS total_qty_on_hand,
        MAX(inv_date_sk) AS latest_inv_date_sk
    FROM inventory
    WHERE inv_quantity_on_hand > 400
    GROUP BY inv_item_sk
    HAVING SUM(inv_quantity_on_hand) > 400
),
store_sales_agg AS (
    SELECT
        ss_item_sk,
        SUM(ss_ext_sales_price) AS store_sales_sum,
        SUM(ss_quantity) AS total_store_quantity,
        MIN(ss_store_sk) AS store_sk,
        MIN(ss_customer_sk) AS customer_sk,
        MIN(ss_cdemo_sk) AS cdemo_sk,
        MIN(ss_addr_sk) AS addr_sk
    FROM store_sales
    WHERE ss_ext_sales_price > 5000
    GROUP BY ss_item_sk
    HAVING SUM(ss_ext_sales_price) > 5000
),
web_sales_agg AS (
    SELECT
        ws_item_sk,
        SUM(ws_ext_sales_price) AS web_sales_sum,
        SUM(ws_quantity) AS total_web_quantity,
        MIN(ws_ship_mode_sk) AS ship_mode_sk
    FROM web_sales
    WHERE ws_ext_sales_price > 2000
    GROUP BY ws_item_sk
    HAVING SUM(ws_ext_sales_price) > 2000
),
-- Items sold in stores but never returned
sold_not_returned AS (
    SELECT ss_item_sk
    FROM store_sales
    EXCEPT
    SELECT cr_item_sk
    FROM catalog_returns
),
-- Items sold both in store and web channels
sold_in_both AS (
    SELECT ss_item_sk
    FROM store_sales
    INTERSECT
    SELECT ws_item_sk
    FROM web_sales
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_current_price,
    s.s_store_name,
    c.c_customer_id,
    ca.ca_state,
    sm.sm_ship_mode_id,
    (ssag.store_sales_sum + wsag.web_sales_sum) AS total_sales_amount,
    ROW_NUMBER() OVER (
        PARTITION BY i.i_category
        ORDER BY (ssag.store_sales_sum + wsag.web_sales_sum) DESC
    ) AS category_sales_rank,
    (
        SELECT SUM(cr2.cr_return_amount)
        FROM catalog_returns cr2
        WHERE cr2.cr_item_sk = i.i_item_sk
    ) AS total_return_amount,
    inv.total_qty_on_hand
FROM store_sales_agg ssag
JOIN web_sales_agg wsag ON ssag.ss_item_sk = wsag.ws_item_sk
JOIN item i ON i.i_item_sk = ssag.ss_item_sk
JOIN inventory_agg inv ON inv.inv_item_sk = i.i_item_sk
JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
JOIN ship_mode sm ON wsag.ship_mode_sk = sm.sm_ship_mode_sk
JOIN store s ON s.s_store_sk = ssag.store_sk
JOIN customer c ON c.c_customer_sk = ssag.customer_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = ssag.cdemo_sk
JOIN customer_address ca ON ca.ca_address_sk = ssag.addr_sk
WHERE
    i.i_current_price BETWEEN 20 AND 200
    AND inv.total_qty_on_hand > 400
    AND cr.cr_return_amount > 50
    AND i.i_item_sk IN (SELECT ss_item_sk FROM sold_not_returned)
    AND i.i_item_sk IN (SELECT ss_item_sk FROM sold_in_both)
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_current_price,
    s.s_store_name,
    c.c_customer_id,
    ca.ca_state,
    sm.sm_ship_mode_id,
    ssag.store_sales_sum,
    wsag.web_sales_sum,
    inv.total_qty_on_hand,
    i.i_item_sk
HAVING
    (ssag.store_sales_sum + wsag.web_sales_sum) > 10000
ORDER BY
    total_sales_amount DESC,
    i.i_item_id
OFFSET 0
LIMIT 100
