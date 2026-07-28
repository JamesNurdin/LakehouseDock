WITH base AS (
    SELECT
        d1.d_year AS d_year,
        s.s_state AS s_state,
        i.i_category AS i_category,
        SUM(ss.ss_net_paid) AS store_sales,
        SUM(cs.cs_net_paid) AS catalog_sales,
        SUM(ws.ws_net_paid) AS web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_txns,
        AVG(CASE WHEN r.r_reason_desc = 'Did not like the warranty' THEN sr.sr_net_loss END) AS avg_warranty_return_loss
    FROM
        store_sales ss
        JOIN date_dim d1 ON ss.ss_sold_date_sk = d1.d_date_sk
        JOIN time_dim t1 ON ss.ss_sold_time_sk = t1.t_time_sk
        JOIN item i ON ss.ss_item_sk = i.i_item_sk
        JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
        JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
        JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
        JOIN store s ON ss.ss_store_sk = s.s_store_sk
        JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
        LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
            AND sr.sr_returned_date_sk = d1.d_date_sk
            AND sr.sr_return_time_sk = t1.t_time_sk
        LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN catalog_sales cs ON cs.cs_sold_date_sk = d1.d_date_sk
            AND cs.cs_item_sk = i.i_item_sk
            AND cs.cs_bill_customer_sk = c.c_customer_sk
            AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
            AND cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
        JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = i.i_item_sk
            AND cr.cr_returned_date_sk = d1.d_date_sk
            AND cr.cr_returned_time_sk = t1.t_time_sk
        JOIN web_sales ws ON ws.ws_sold_date_sk = d1.d_date_sk
            AND ws.ws_item_sk = i.i_item_sk
            AND ws.ws_bill_customer_sk = c.c_customer_sk
            AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
            AND ws.ws_bill_addr_sk = ca.ca_address_sk
        JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
        LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
            AND wr.wr_returned_date_sk = d1.d_date_sk
            AND wr.wr_returned_time_sk = t1.t_time_sk
        LEFT JOIN inventory inv ON inv.inv_date_sk = d1.d_date_sk
            AND inv.inv_item_sk = i.i_item_sk
            AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        d1.d_year = 2001
        AND i.i_brand = 'Brand#23'
        AND s.s_state = 'CA'
        AND cc.cc_division = 3
        AND r.r_reason_desc = 'Did not like the warranty'
        AND ws_site.web_country = 'United States'
    GROUP BY
        d1.d_year,
        s.s_state,
        i.i_category
)
SELECT
    d_year,
    s_state,
    i_category,
    store_sales,
    catalog_sales,
    web_sales,
    store_txns,
    avg_warranty_return_loss,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY store_sales DESC) AS store_sales_rank
FROM base
ORDER BY store_sales DESC
LIMIT 100
