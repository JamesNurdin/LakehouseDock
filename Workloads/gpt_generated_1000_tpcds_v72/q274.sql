WITH web_data AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_time_sk,
        ws.ws_warehouse_sk,
        ws.ws_ship_mode_sk,
        ws.ws_net_paid,
        wr.wr_return_quantity,
        wr.wr_net_loss,
        wr.wr_reason_sk,
        ws.ws_item_sk
    FROM web_sales ws
    JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND ws.ws_item_sk = wr.wr_item_sk
)
SELECT DISTINCT
    t.t_time,
    t.t_meal_time,
    cp.cp_catalog_page_id,
    cr.cr_return_amount,
    cr.cr_net_loss,
    r.r_reason_desc,
    sm.sm_type,
    w.w_warehouse_name,
    wd.ws_order_number,
    wd.wr_return_quantity,
    wd.wr_net_loss,
    ss.ss_net_paid AS store_sales_net_paid,
    RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY cr.cr_net_loss DESC) AS loss_rank,
    (SELECT avg(ss2.ss_net_paid) FROM store_sales ss2) AS avg_store_sales_net_paid
FROM time_dim t
-- Catalog Returns branch
JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = t.t_time_sk
JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
JOIN customer_address ca_ret
    ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
-- Store Sales branch
JOIN store_sales ss
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
-- Web Sales / Returns branch via CTE
JOIN web_data wd
    ON wd.ws_sold_time_sk = t.t_time_sk
JOIN ship_mode sm_ws
    ON wd.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
JOIN warehouse w_ws
    ON wd.ws_warehouse_sk = w_ws.w_warehouse_sk
JOIN reason r_wr
    ON wd.wr_reason_sk = r_wr.r_reason_sk
WHERE
    t.t_meal_time = 'lunch'
    AND w.w_city IN ('Liberty', 'Shiloh')
    AND sm.sm_type = 'AIR'
    AND r.r_reason_desc LIKE '%damage%'
    AND ss.ss_quantity > 5
ORDER BY
    loss_rank,
    cr.cr_net_loss DESC
LIMIT 100
