WITH
    /* Aggregate catalog sales per item and catalog page */
    cat_sales_agg AS (
        SELECT
            cs_item_sk,
            cs_catalog_page_sk,
            SUM(cs_net_paid_inc_ship_tax) AS total_net_paid,
            COUNT(*) AS sales_cnt
        FROM catalog_sales
        GROUP BY cs_item_sk, cs_catalog_page_sk
    ),
    /* A small Bernoulli sample of web sales */
    web_sales_sample AS (
        SELECT *
        FROM web_sales TABLESAMPLE BERNOULLI (10)
    ),
    /* Orders that appear in both catalog and web returns */
    returns_intersect AS (
        SELECT cr_order_number AS order_number
        FROM catalog_returns
        INTERSECT
        SELECT wr_order_number AS order_number
        FROM web_returns
    ),
    /* Distinct reason rows (to demonstrate DISTINCT usage) */
    distinct_reasons AS (
        SELECT DISTINCT r_reason_sk, r_reason_desc
        FROM reason
    ),
    /* Core join of all tables – many roles for the same dimensions */
    final_base AS (
        SELECT
            cp.cp_catalog_page_sk,
            cp.cp_catalog_page_id,
            cr.cr_return_amount,
            cr.cr_return_quantity,
            cr.cr_fee,
            cr.cr_return_amt_inc_tax,
            dr.r_reason_desc,
            sm.sm_ship_mode_id,
            td.t_hour,
            ca.ca_state AS refund_state,
            hd.hd_income_band_sk AS refund_income_band,
            c.c_customer_id AS refund_customer_id,
            c_ship.c_customer_id AS returning_customer_id,
            ca2.ca_state AS returning_state,
            hd2.hd_income_band_sk AS returning_income_band,
            ws.ws_quantity,
            ws.ws_net_paid,
            ws.ws_net_profit,
            wpa.wp_url,
            -- LATERAL sub‑query that uses a column from the preceding row
            lt.ten_percent_return
        FROM catalog_returns cr
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN distinct_reasons dr ON cr.cr_reason_sk = dr.r_reason_sk
        JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
        JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN customer c_ship ON cr.cr_returning_customer_sk = c_ship.c_customer_sk
        JOIN customer_address ca2 ON cr.cr_returning_addr_sk = ca2.ca_address_sk
        JOIN household_demographics hd2 ON cr.cr_returning_hdemo_sk = hd2.hd_demo_sk
        JOIN returns_intersect ri ON cr.cr_order_number = ri.order_number
        LEFT JOIN web_sales_sample ws ON cr.cr_item_sk = ws.ws_item_sk
        LEFT JOIN web_page wpa ON ws.ws_web_page_sk = wpa.wp_web_page_sk
        CROSS JOIN LATERAL (
            SELECT cr.cr_return_amount * 0.1 AS ten_percent_return
        ) lt
    )
SELECT
    ROW_NUMBER() OVER (ORDER BY csa.total_net_paid DESC) AS rn,
    fb.cp_catalog_page_id,
    fb.r_reason_desc,
    fb.sm_ship_mode_id,
    fb.t_hour,
    fb.refund_state,
    fb.refund_income_band,
    fb.refund_customer_id,
    fb.returning_customer_id,
    fb.returning_state,
    fb.returning_income_band,
    fb.cr_return_amount,
    fb.cr_return_quantity,
    fb.cr_fee,
    fb.cr_return_amt_inc_tax,
    fb.ten_percent_return,
    fb.ws_quantity,
    fb.ws_net_paid,
    fb.ws_net_profit,
    fb.wp_url,
    csa.total_net_paid,
    csa.sales_cnt
FROM final_base fb
JOIN cat_sales_agg csa ON fb.cp_catalog_page_sk = csa.cs_catalog_page_sk
ORDER BY rn
OFFSET 10
LIMIT 100
