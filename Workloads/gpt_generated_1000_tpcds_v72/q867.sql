WITH base AS (
    SELECT
        w.w_warehouse_name,
        cp.cp_catalog_number,
        cc.cc_name,
        td.t_hour,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        COUNT(DISTINCT cr.cr_order_number) AS return_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS sales_tickets
    FROM catalog_returns cr
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cr.cr_returned_time_sk = td.t_time_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN inventory i ON i.inv_warehouse_sk = w.w_warehouse_sk
    JOIN store_sales ss
        ON ss.ss_customer_sk = c.c_customer_sk
        AND ss.ss_sold_time_sk = td.t_time_sk
    WHERE
        cp.cp_catalog_number IN (1, 3, 12)
        AND cc.cc_state = 'CA'
        AND w.w_gmt_offset = -6.00
        AND ca.ca_state = 'TX'
        AND td.t_hour BETWEEN 9 AND 17
    GROUP BY
        w.w_warehouse_name,
        cp.cp_catalog_number,
        cc.cc_name,
        td.t_hour
    HAVING
        SUM(cr.cr_return_amount) > 1000
        AND SUM(ss.ss_ext_sales_price) > 5000
)
SELECT
    b.w_warehouse_name,
    b.cp_catalog_number,
    b.total_return_amount,
    b.total_sales_amount,
    (b.total_return_amount / NULLIF(b.total_sales_amount, 0)) AS return_to_sales_ratio,
    AVG(b.total_return_amount / NULLIF(b.total_sales_amount, 0)) OVER (PARTITION BY b.w_warehouse_name) AS avg_ratio_warehouse,
    CASE
        WHEN b.total_return_amount > (SELECT AVG(total_return_amount) FROM base) THEN 'ABOVE_AVG_RETURN'
        ELSE 'BELOW_AVG_RETURN'
    END AS return_category
FROM base b
WHERE b.total_sales_amount > 0
ORDER BY avg_ratio_warehouse DESC
LIMIT 100
