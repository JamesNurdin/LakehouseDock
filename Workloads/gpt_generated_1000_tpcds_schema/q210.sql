WITH return_orders AS (
        SELECT cr_order_number
        FROM catalog_returns
    ),
    web_orders AS (
        SELECT ws_order_number AS order_number
        FROM web_sales
    ),
    exclusive_returns AS (
        SELECT cr_order_number
        FROM return_orders
        EXCEPT
        SELECT order_number
        FROM web_orders
    ),
    agg AS (
        SELECT
            s.s_manager,
            sm_ret.sm_carrier AS return_carrier,
            sm_ship.sm_carrier AS ship_carrier,
            COUNT(DISTINCT cr.cr_order_number) AS return_orders_cnt,
            SUM(cr.cr_net_loss) AS total_net_loss,
            SUM(ws.ws_net_paid) AS total_web_paid
        FROM catalog_returns cr
        -- refunded‑customer side
        JOIN customer cust_ref ON cr.cr_refunded_customer_sk = cust_ref.c_customer_sk
        JOIN customer_address ca_ref ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
        -- returning‑customer side (second alias)
        JOIN customer cust_ret ON cr.cr_returning_customer_sk = cust_ret.c_customer_sk
        JOIN customer_address ca_ret ON cr.cr_returning_addr_sk = ca_ret.ca_address_sk
        -- return‑specific dimensions
        JOIN ship_mode sm_ret ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
        JOIN warehouse wh_ret ON cr.cr_warehouse_sk = wh_ret.w_warehouse_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        -- link to web_sales via the same refunded customer
        JOIN web_sales ws ON ws.ws_bill_customer_sk = cust_ref.c_customer_sk
        JOIN customer ws_cust ON ws.ws_bill_customer_sk = ws_cust.c_customer_sk
        JOIN customer_address ws_addr ON ws.ws_bill_addr_sk = ws_addr.ca_address_sk
        JOIN ship_mode sm_ship ON ws.ws_ship_mode_sk = sm_ship.sm_ship_mode_sk
        JOIN warehouse wh_ship ON ws.ws_warehouse_sk = wh_ship.w_warehouse_sk
        JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        -- link to store_sales via the same refunded customer
        JOIN store_sales ss ON ss.ss_customer_sk = cust_ref.c_customer_sk
        JOIN customer ss_cust ON ss.ss_customer_sk = ss_cust.c_customer_sk
        JOIN customer_address ss_addr ON ss.ss_addr_sk = ss_addr.ca_address_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        WHERE cr.cr_order_number IN (SELECT cr_order_number FROM exclusive_returns)
          AND sm_ret.sm_carrier = 'UPS'
          AND s.s_manager = 'Brett Yates'
        GROUP BY s.s_manager, sm_ret.sm_carrier, sm_ship.sm_carrier
    )
SELECT *
FROM agg
ORDER BY total_net_loss DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
