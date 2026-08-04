WITH
    inventory_sample AS (
        SELECT inv_item_sk, inv_quantity_on_hand
        FROM inventory TABLESAMPLE BERNOULLI (5)
    ),
    sales_orders AS (
        SELECT ws.ws_order_number, ws.ws_item_sk
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        WHERE ws.ws_sold_date_sk = 2450948
    ),
    returns_without_sales AS (
        SELECT ws_order_number
        FROM web_sales
        EXCEPT
        SELECT wr_order_number FROM web_returns
    ),
    base AS (
        SELECT
            cr.cr_returned_date_sk,
            cr.cr_return_amount,
            i.i_item_sk,
            i.i_item_id,
            i.i_category,
            cc.cc_name,
            sm.sm_ship_mode_id,
            ca_ref.ca_city AS refunded_city,
            ca_ret.ca_city AS returning_city,
            cd_ref.cd_gender AS refunded_gender,
            cd_ret.cd_gender AS returning_gender,
            hd_ref.hd_buy_potential AS refunded_buy_pot,
            hd_ret.hd_buy_potential AS returning_buy_pot,
            ws.ws_order_number,
            ws.ws_sales_price,
            ws.ws_quantity,
            wr.wr_return_amt,
            inv_samp.inv_quantity_on_hand,
            wp_ws.wp_type AS sales_page_type,
            wp_wr.wp_type AS return_page_type
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
        JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
        JOIN customer_demographics cd_ref ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
        JOIN customer_demographics cd_ret ON cr.cr_returning_cdemo_sk = cd_ret.cd_demo_sk
        JOIN household_demographics hd_ref ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
        JOIN household_demographics hd_ret ON cr.cr_returning_hdemo_sk = hd_ret.hd_demo_sk
        LEFT JOIN web_sales ws ON cr.cr_order_number = ws.ws_order_number
        LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
        LEFT JOIN inventory_sample inv_samp ON i.i_item_sk = inv_samp.inv_item_sk
        LEFT JOIN web_page wp_ws ON ws.ws_web_page_sk = wp_ws.wp_web_page_sk
        LEFT JOIN web_page wp_wr ON wr.wr_web_page_sk = wp_wr.wp_web_page_sk
        WHERE EXISTS (
            SELECT 1 FROM sales_orders so WHERE so.ws_item_sk = i.i_item_sk
        )
    )
SELECT
    b.i_category AS category,
    b.sm_ship_mode_id AS ship_mode_id,
    SUM(b.cr_return_amount) AS total_return_amount,
    COUNT(DISTINCT b.ws_order_number) AS orders_with_returns,
    CAST(NULL AS BIGINT) AS sales_without_returns,
    lt.total_qty
FROM base b
CROSS JOIN LATERAL (
    SELECT SUM(ws_quantity) AS total_qty
    FROM web_sales ws
    WHERE ws.ws_item_sk = b.i_item_sk
) lt
CROSS JOIN (VALUES ('A'), ('B')) AS dim(label)
GROUP BY b.i_category, b.sm_ship_mode_id, lt.total_qty, dim.label
HAVING SUM(b.cr_return_amount) > 100

UNION DISTINCT

SELECT
    i.i_category AS category,
    sm.sm_ship_mode_id AS ship_mode_id,
    CAST(0 AS DECIMAL(7,2)) AS total_return_amount,
    CAST(0 AS BIGINT) AS orders_with_returns,
    COUNT(*) AS sales_without_returns,
    lt.total_qty
FROM returns_without_sales rws
JOIN web_sales ws ON rws.ws_order_number = ws.ws_order_number
JOIN item i ON ws.ws_item_sk = i.i_item_sk
JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
CROSS JOIN LATERAL (
    SELECT SUM(ws_quantity) AS total_qty
    FROM web_sales ws2
    WHERE ws2.ws_item_sk = i.i_item_sk
) lt
CROSS JOIN (VALUES ('A'), ('B')) AS dim(label)
GROUP BY i.i_category, sm.sm_ship_mode_id, lt.total_qty, dim.label

ORDER BY category, ship_mode_id, total_return_amount DESC
LIMIT 100
