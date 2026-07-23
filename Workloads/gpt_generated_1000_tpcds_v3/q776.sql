WITH item_filtered AS (
    SELECT DISTINCT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_current_price
    FROM
        item i
    WHERE
        i.i_current_price > 500
)
SELECT *
FROM (
    SELECT
        d_cs.d_year,
        i_f.i_category,
        cc.cc_name,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT c.c_customer_id) AS distinct_customers,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_catalog_returns,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_returns,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_returns,
        (SELECT MAX(w_warehouse_sq_ft) FROM warehouse) AS max_warehouse_sq_ft
    FROM
        catalog_sales cs
        JOIN date_dim d_cs ON cs.cs_sold_date_sk = d_cs.d_date_sk
        JOIN time_dim t_cs ON cs.cs_sold_time_sk = t_cs.t_time_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        JOIN item_filtered i_f ON cs.cs_item_sk = i_f.i_item_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        LEFT JOIN store_sales ss
            ON ss.ss_sold_date_sk = d_cs.d_date_sk
            AND ss.ss_item_sk = i_f.i_item_sk
            AND ss.ss_customer_sk = c.c_customer_sk
        LEFT JOIN store_returns sr
            ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_item_sk = ss.ss_item_sk
        LEFT JOIN web_returns wr
            ON wr.wr_item_sk = i_f.i_item_sk
        LEFT JOIN web_site ws
            ON ws.web_open_date_sk = d_cs.d_date_sk
    WHERE
        d_cs.d_date = DATE '2001-01-01'
        AND cc.cc_state = 'CA'
        AND ws.web_gmt_offset = -5.00
        AND cs.cs_quantity > (SELECT AVG(ss2.ss_quantity) FROM store_sales ss2)
        AND EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_ticket_number = ss.ss_ticket_number
              AND sr2.sr_return_amt > 0
        )
    GROUP BY
        d_cs.d_year,
        i_f.i_category,
        cc.cc_name
    UNION ALL
    SELECT
        d_cs2.d_year,
        i_f2.i_category,
        cc2.cc_name,
        SUM(cs2.cs_net_paid) AS total_net_paid,
        SUM(cs2.cs_quantity) AS total_quantity,
        COUNT(DISTINCT c2.c_customer_id) AS distinct_customers,
        SUM(COALESCE(cr2.cr_return_amount, 0)) AS total_catalog_returns,
        SUM(COALESCE(sr2.sr_return_amt, 0)) AS total_store_returns,
        SUM(COALESCE(wr2.wr_return_amt, 0)) AS total_web_returns,
        (SELECT MAX(w_warehouse_sq_ft) FROM warehouse) AS max_warehouse_sq_ft
    FROM
        catalog_sales cs2
        JOIN date_dim d_cs2 ON cs2.cs_sold_date_sk = d_cs2.d_date_sk
        JOIN time_dim t_cs2 ON cs2.cs_sold_time_sk = t_cs2.t_time_sk
        JOIN call_center cc2 ON cs2.cs_call_center_sk = cc2.cc_call_center_sk
        JOIN catalog_page cp2 ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
        JOIN ship_mode sm2 ON cs2.cs_ship_mode_sk = sm2.sm_ship_mode_sk
        JOIN warehouse w2 ON cs2.cs_warehouse_sk = w2.w_warehouse_sk
        JOIN customer c2 ON cs2.cs_bill_customer_sk = c2.c_customer_sk
        JOIN customer_address ca2 ON cs2.cs_bill_addr_sk = ca2.ca_address_sk
        JOIN customer_demographics cd2 ON cs2.cs_bill_cdemo_sk = cd2.cd_demo_sk
        JOIN item_filtered i_f2 ON cs2.cs_item_sk = i_f2.i_item_sk
        LEFT JOIN catalog_returns cr2 ON cr2.cr_order_number = cs2.cs_order_number
        LEFT JOIN store_sales ss2
            ON ss2.ss_sold_date_sk = d_cs2.d_date_sk
            AND ss2.ss_item_sk = i_f2.i_item_sk
            AND ss2.ss_customer_sk = c2.c_customer_sk
        LEFT JOIN store_returns sr2
            ON sr2.sr_ticket_number = ss2.ss_ticket_number
            AND sr2.sr_item_sk = ss2.ss_item_sk
        LEFT JOIN web_returns wr2
            ON wr2.wr_item_sk = i_f2.i_item_sk
        LEFT JOIN web_site ws2
            ON ws2.web_open_date_sk = d_cs2.d_date_sk
    WHERE
        d_cs2.d_date = DATE '2002-01-01'
        AND cc2.cc_state = 'CA'
        AND ws2.web_gmt_offset = -5.00
        AND cs2.cs_quantity > (SELECT AVG(ss3.ss_quantity) FROM store_sales ss3)
        AND EXISTS (
            SELECT 1
            FROM store_returns sr3
            WHERE sr3.sr_ticket_number = ss2.ss_ticket_number
              AND sr3.sr_return_amt > 0
        )
    GROUP BY
        d_cs2.d_year,
        i_f2.i_category,
        cc2.cc_name
) combined
ORDER BY total_net_paid DESC
LIMIT 100
