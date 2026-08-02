WITH
    inventory_summary AS (
        SELECT
            inv_date_sk,
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_qty
        FROM inventory
        GROUP BY inv_date_sk, inv_warehouse_sk
    ),
    aggregated_data AS (
        SELECT
            d_sales.d_year AS d_year,
            c.c_customer_id AS c_customer_id,
            p_store.p_promo_id AS p_promo_id,
            w_cr.w_warehouse_name AS w_warehouse_name,
            SUM(ss.ss_net_paid) AS total_sales,
            SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_return_amount,
            SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_return_amount,
            SUM(COALESCE(i_sum.total_qty, 0)) AS total_inventory_qty,
            COUNT(DISTINCT r_store.r_reason_desc) AS distinct_store_return_reasons,
            COUNT(DISTINCT r_cat.r_reason_desc) AS distinct_catalog_return_reasons,
            (
                SELECT SUM(ws2.ws_net_paid)
                FROM web_sales ws2
                WHERE ws2.ws_bill_customer_sk = c.c_customer_sk
            ) AS total_customer_web_sales,
            c.c_customer_sk -- needed for the correlated subquery
        FROM store_sales ss
        JOIN date_dim d_sales
            ON ss.ss_sold_date_sk = d_sales.d_date_sk
        JOIN customer c
            ON ss.ss_customer_sk = c.c_customer_sk
        JOIN household_demographics hd
            ON ss.ss_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN promotion p_store
            ON ss.ss_promo_sk = p_store.p_promo_sk
        LEFT JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = ss.ss_item_sk
        LEFT JOIN reason r_store
            ON sr.sr_reason_sk = r_store.r_reason_sk
        LEFT JOIN date_dim d_ret
            ON sr.sr_returned_date_sk = d_ret.d_date_sk
        LEFT JOIN catalog_returns cr
            ON cr.cr_refunded_customer_sk = c.c_customer_sk
            AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN date_dim d_cr_ret
            ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
        LEFT JOIN catalog_page cp
            ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        LEFT JOIN date_dim d_cp_start
            ON cp.cp_start_date_sk = d_cp_start.d_date_sk
        LEFT JOIN date_dim d_cp_end
            ON cp.cp_end_date_sk = d_cp_end.d_date_sk
        LEFT JOIN warehouse w_cr
            ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
        LEFT JOIN inventory_summary i_sum
            ON i_sum.inv_date_sk = d_sales.d_date_sk
            AND i_sum.inv_warehouse_sk = w_cr.w_warehouse_sk
        LEFT JOIN reason r_cat
            ON cr.cr_reason_sk = r_cat.r_reason_sk
        LEFT JOIN web_sales ws
            ON ws.ws_bill_customer_sk = c.c_customer_sk
        LEFT JOIN promotion p_web
            ON ws.ws_promo_sk = p_web.p_promo_sk
        LEFT JOIN date_dim d_ws_sold
            ON ws.ws_sold_date_sk = d_ws_sold.d_date_sk
        LEFT JOIN date_dim d_ws_ship
            ON ws.ws_ship_date_sk = d_ws_ship.d_date_sk
        LEFT JOIN warehouse w_ws
            ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
        GROUP BY
            d_sales.d_year,
            c.c_customer_id,
            p_store.p_promo_id,
            w_cr.w_warehouse_name,
            c.c_customer_sk
    )
SELECT
    d_year,
    c_customer_id,
    p_promo_id,
    w_warehouse_name,
    total_sales,
    total_store_return_amount,
    total_catalog_return_amount,
    total_inventory_qty,
    distinct_store_return_reasons,
    distinct_catalog_return_reasons,
    total_customer_web_sales,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
FROM aggregated_data
ORDER BY total_sales DESC
LIMIT 100
