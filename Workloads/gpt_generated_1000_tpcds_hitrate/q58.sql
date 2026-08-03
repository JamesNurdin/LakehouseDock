WITH all_data AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        i.i_brand,
        i.i_brand_id,
        i.i_color,
        w.w_state,
        sm.sm_type,
        r.r_reason_desc,
        ca.ca_country,
        cd.cd_gender,
        hd.hd_income_band_sk,
        td.t_hour,
        cr.cr_return_amount,
        cr.cr_net_loss,
        sr.sr_return_quantity,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_order_number,
        inv.inv_quantity_on_hand,
        wp.wp_max_ad_count
    FROM item i
    JOIN catalog_returns cr               ON cr.cr_item_sk = i.i_item_sk
    JOIN store_returns sr                ON sr.sr_item_sk = i.i_item_sk
    JOIN web_sales ws                    ON ws.ws_item_sk = i.i_item_sk
    JOIN web_returns wr                  ON wr.wr_item_sk = i.i_item_sk
                                         AND wr.wr_order_number = ws.ws_order_number
    JOIN inventory inv                   ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w                     ON w.w_warehouse_sk = cr.cr_warehouse_sk
    JOIN ship_mode sm                    ON sm.sm_ship_mode_sk = cr.cr_ship_mode_sk
    JOIN reason r                        ON r.r_reason_sk = cr.cr_reason_sk
    JOIN time_dim td                     ON td.t_time_sk = cr.cr_returned_time_sk
    JOIN customer c                      ON c.c_customer_sk = cr.cr_refunded_customer_sk
    JOIN customer_address ca             ON ca.ca_address_sk = cr.cr_refunded_addr_sk
    JOIN customer_demographics cd        ON cd.cd_demo_sk = cr.cr_refunded_cdemo_sk
    JOIN household_demographics hd       ON hd.hd_demo_sk = cr.cr_refunded_hdemo_sk
    JOIN web_page wp                     ON wp.wp_web_page_sk = ws.ws_web_page_sk
)
SELECT
    c_customer_id,
    i_brand,
    w_state,
    r_reason_desc,
    COUNT(DISTINCT ws_order_number)               AS distinct_orders,
    SUM(cr_return_amount)                         AS total_return_amount,
    SUM(ws_net_profit)                            AS total_net_profit,
    AVG(inv_quantity_on_hand)                     AS avg_inventory_qty,
    MAX(t_hour)                                   AS latest_hour,
    SUM(ws_ext_sales_price) / NULLIF(SUM(cr_return_amount), 0) AS sales_to_return_ratio
FROM all_data
WHERE
    i_color = 'Red'
    AND i_brand_id = 25
    AND w_state = 'CA'
    AND sm_type = 'AIR'
    AND r_reason_desc LIKE '%price%'
    AND ca_country = 'FRENCH GUIANA'
    AND cd_gender = 'M'
    AND hd_income_band_sk = 5
    AND t_hour BETWEEN 9 AND 17
    AND c_customer_sk NOT IN (
        SELECT ws_bill_customer_sk
        FROM web_sales
        WHERE ws_net_profit > 1000
    )
GROUP BY
    c_customer_id,
    i_brand,
    w_state,
    r_reason_desc
ORDER BY
    total_net_profit DESC
LIMIT 100
