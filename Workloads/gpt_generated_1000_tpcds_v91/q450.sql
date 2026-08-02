WITH main AS (
    SELECT
        s.s_store_name,
        i.i_category,
        td.t_hour,
        CASE WHEN SUM(ss.ss_net_paid) > 1000 THEN 'High' ELSE 'Low' END AS sales_category,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(cs.cs_ext_sales_price) AS avg_catalog_sales_price,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        MIN(cr.cr_return_amount) AS min_return_amount,
        MAX(wr.wr_return_amt) AS max_web_return_amt,
        SUM(CASE WHEN ss.ss_quantity > 5 THEN ss.ss_net_paid ELSE 0 END) AS high_qty_sales_sum
    FROM
        store_sales ss
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
        JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
            AND cs.cs_sold_time_sk = td.t_time_sk
            AND cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = i.i_item_sk
        JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = i.i_item_sk
            AND sr.sr_store_sk = s.s_store_sk
        JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
            AND wr.wr_returned_time_sk = td.t_time_sk
            AND wr.wr_refunded_customer_sk = c.c_customer_sk
        JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
        JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
            AND inv.inv_warehouse_sk = w.w_warehouse_sk
        JOIN customer_demographics cd_cur ON c.c_current_cdemo_sk = cd_cur.cd_demo_sk
        JOIN household_demographics hd_cur ON c.c_current_hdemo_sk = hd_cur.hd_demo_sk
    WHERE
        cc.cc_tax_percentage BETWEEN 0.05 AND 0.10
        AND s.s_state = 'CA'
        AND td.t_hour BETWEEN 12 AND 13
        AND i.i_current_price > 100
        AND cd.cd_purchase_estimate >= 8000
        AND NOT EXISTS (
            SELECT 1 FROM web_returns wr2
            WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
              AND wr2.wr_return_amt > 500
        )
        AND i.i_item_sk IN (
            SELECT cr_item_sk FROM catalog_returns
            INTERSECT
            SELECT sr_item_sk FROM store_returns
        )
    GROUP BY ROLLUP (s.s_store_name, i.i_category, td.t_hour)
)
SELECT
    s_store_name,
    i_category,
    t_hour,
    sales_category,
    total_net_paid,
    avg_catalog_sales_price,
    distinct_tickets,
    min_return_amount,
    max_web_return_amt,
    high_qty_sales_sum
FROM main
LIMIT 100
