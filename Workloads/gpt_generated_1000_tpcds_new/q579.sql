WITH
    -- Orders that had a return (catalog or web)
    orders_with_returns AS (
        SELECT DISTINCT cr_order_number AS order_number FROM catalog_returns
        UNION
        SELECT DISTINCT wr_order_number AS order_number FROM web_returns
    ),
    -- Orders that had a sale (store or web)
    orders_with_sales AS (
        SELECT DISTINCT ss_ticket_number AS order_number FROM store_sales
        UNION
        SELECT DISTINCT ws_order_number AS order_number FROM web_sales
    ),
    -- Orders that have sales but no returns (using EXCEPT)
    orders_without_returns AS (
        SELECT order_number FROM orders_with_sales
        EXCEPT
        SELECT order_number FROM orders_with_returns
    ),
    -- Main analytical query
    final AS (
        SELECT
            i.i_category AS category,
            sm.sm_carrier AS carrier,
            COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_cnt,
            COUNT(DISTINCT ws.ws_order_number) AS web_sales_cnt,
            SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid) AS total_net_paid,
            SUM(CASE WHEN cr.cr_order_number IS NOT NULL THEN 1 ELSE 0 END) +
            SUM(CASE WHEN wr.wr_order_number IS NOT NULL THEN 1 ELSE 0 END) AS total_returns,
            AVG(ss.ss_ext_discount_amt) AS avg_store_discount,
            (
                SELECT MAX(ib2.ib_upper_bound)
                FROM income_band ib2
                WHERE ib2.ib_income_band_sk = hd.hd_income_band_sk
            ) AS max_income_upper,
            (
                SELECT MAX(i3.i_category_id)
                FROM item i3
                WHERE i3.i_category_id = 1
            ) AS compare_val
        FROM store_sales ss
        JOIN date_dim d_sold ON ss.ss_sold_date_sk = d_sold.d_date_sk
        JOIN time_dim t_sold ON ss.ss_sold_time_sk = t_sold.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_item_sk = i.i_item_sk
            AND cr.cr_returned_date_sk = d_sold.d_date_sk
        LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        LEFT JOIN web_sales ws
            ON ws.ws_item_sk = i.i_item_sk
            AND ws.ws_sold_date_sk = d_sold.d_date_sk
        LEFT JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
        LEFT JOIN date_dim d_ship ON ws.ws_ship_date_sk = d_ship.d_date_sk
        LEFT JOIN web_returns wr
            ON wr.wr_item_sk = i.i_item_sk
            AND wr.wr_order_number = ws.ws_order_number
        LEFT JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
        LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
        LEFT JOIN household_demographics hd_wr ON wr.wr_refunded_hdemo_sk = hd_wr.hd_demo_sk
        WHERE i.i_category_id > (
                SELECT MAX(i4.i_category_id)
                FROM item i4
                WHERE i4.i_category_id = 1
            )
          AND EXISTS (
                SELECT 1
                FROM orders_without_returns owr
                WHERE owr.order_number = ss.ss_ticket_number
                   OR owr.order_number = ws.ws_order_number
            )
        GROUP BY ROLLUP(i.i_category, sm.sm_carrier, hd.hd_income_band_sk)
        HAVING (SUM(ss.ss_net_paid) + SUM(ws.ws_net_paid)) > 0
        ORDER BY category, carrier
        LIMIT 100
    )
SELECT * FROM final
