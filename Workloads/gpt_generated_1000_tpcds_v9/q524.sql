/* Goal: Combine store return and web return records, compute loss categories, enrich with demographic and warehouse information, calculate per‑item inventory metrics, and list the highest net‑loss returns. */
WITH store_ret AS (
    SELECT
        CAST('store' AS varchar) AS return_source,
        sr.sr_returned_date_sk AS return_date_sk,
        sr.sr_net_loss AS net_loss,
        CASE
            WHEN sr.sr_net_loss > 1000 THEN 'High'
            WHEN sr.sr_net_loss > 100  THEN 'Medium'
            ELSE 'Low'
        END AS loss_category,
        s.s_store_name AS location_name,
        s.s_state AS location_state,
        cd.cd_gender AS gender,
        hd.hd_vehicle_count AS vehicle_count,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        CAST(
            (SELECT SUM(i.inv_quantity_on_hand)
             FROM inventory i
             WHERE i.inv_item_sk = sr.sr_item_sk)
            AS double
        ) AS metric_value,
        (SELECT MAX(w.w_warehouse_sq_ft) FROM warehouse w) AS max_warehouse_sq_ft
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE sr.sr_returned_date_sk BETWEEN 2451699 AND 2452273
      AND EXISTS (
          SELECT 1 FROM inventory i
          WHERE i.inv_item_sk = sr.sr_item_sk AND i.inv_quantity_on_hand > 0
      )
),
web_ret AS (
    SELECT
        CAST('web' AS varchar) AS return_source,
        wr.wr_returned_date_sk AS return_date_sk,
        wr.wr_net_loss AS net_loss,
        CASE
            WHEN wr.wr_net_loss > 500 THEN 'High'
            ELSE 'Low'
        END AS loss_category,
        wp.wp_url AS location_name,
        w.w_state AS location_state,
        cd.cd_gender AS gender,
        hd.hd_vehicle_count AS vehicle_count,
        ib.ib_lower_bound AS income_lower,
        ib.ib_upper_bound AS income_upper,
        CAST(ws.ws_quantity AS double) AS metric_value,
        (SELECT MAX(w2.w_warehouse_sq_ft) FROM warehouse w2) AS max_warehouse_sq_ft
    FROM web_returns wr
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
                     AND wr.wr_item_sk = ws.ws_item_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN time_dim t ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2451699 AND 2452273
      AND EXISTS (
          SELECT 1 FROM inventory i
          WHERE i.inv_item_sk = wr.wr_item_sk AND i.inv_quantity_on_hand > 0
      )
)
SELECT
    return_source,
    return_date_sk,
    net_loss,
    loss_category,
    location_name,
    location_state,
    gender,
    vehicle_count,
    income_lower,
    income_upper,
    metric_value,
    max_warehouse_sq_ft
FROM store_ret
UNION ALL
SELECT
    return_source,
    return_date_sk,
    net_loss,
    loss_category,
    location_name,
    location_state,
    gender,
    vehicle_count,
    income_lower,
    income_upper,
    metric_value,
    max_warehouse_sq_ft
FROM web_ret
ORDER BY net_loss DESC
LIMIT 100
