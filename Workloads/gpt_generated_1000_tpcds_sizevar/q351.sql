(
    SELECT
        d.d_year,
        i.i_category,
        r.r_reason_desc,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        COUNT(DISTINCT cs.cs_order_number) AS unique_orders,
        AVG(CASE WHEN cr.cr_return_amount > 0 THEN cr.cr_return_amount END) AS avg_return_amount,
        MIN(ws.web_tax_percentage) AS min_site_tax
    FROM tpcds.date_dim d
    JOIN tpcds.call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
                               AND cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.item i ON i.i_item_sk = cs.cs_item_sk
    JOIN tpcds.customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN tpcds.customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
    JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
                              AND inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
                               AND ss.ss_item_sk = i.i_item_sk
                               AND ss.ss_customer_sk = c.c_customer_sk
                               AND ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.store st ON st.s_store_sk = ss.ss_store_sk
    JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                                 AND sr.sr_item_sk = i.i_item_sk
                                 AND sr.sr_customer_sk = c.c_customer_sk
                                 AND sr.sr_addr_sk = ca.ca_address_sk
                                 AND sr.sr_store_sk = st.s_store_sk
    JOIN tpcds.reason r ON r.r_reason_sk = sr.sr_reason_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                                   AND cr.cr_item_sk = i.i_item_sk
                                   AND cr.cr_refunded_customer_sk = c.c_customer_sk
                                   AND cr.cr_refunded_addr_sk = ca.ca_address_sk
                                   AND cr.cr_call_center_sk = cc.cc_call_center_sk
                                   AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
                                   AND cr.cr_reason_sk = r.r_reason_sk
                                   AND cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
                           AND wp.wp_customer_sk = c.c_customer_sk
    JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                               AND wr.wr_item_sk = i.i_item_sk
                               AND wr.wr_refunded_customer_sk = c.c_customer_sk
                               AND wr.wr_refunded_addr_sk = ca.ca_address_sk
                               AND wr.wr_web_page_sk = wp.wp_web_page_sk
                               AND wr.wr_reason_sk = r.r_reason_sk
    JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 1999
      AND i.i_brand = 'Brand#12'
      AND ca.ca_country = 'United States'
      AND sm.sm_type = 'AIR'
    GROUP BY d.d_year, i.i_category, r.r_reason_desc, ws.web_tax_percentage

    UNION DISTINCT

    SELECT
        d.d_year,
        i.i_category,
        r.r_reason_desc,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        COUNT(DISTINCT cs.cs_order_number) AS unique_orders,
        AVG(CASE WHEN cr.cr_return_amount > 0 THEN cr.cr_return_amount END) AS avg_return_amount,
        MIN(ws.web_tax_percentage) AS min_site_tax
    FROM tpcds.date_dim d
    JOIN tpcds.call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
                               AND cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.item i ON i.i_item_sk = cs.cs_item_sk
    JOIN tpcds.customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN tpcds.customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
    JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
                              AND inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
                               AND ss.ss_item_sk = i.i_item_sk
                               AND ss.ss_customer_sk = c.c_customer_sk
                               AND ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.store st ON st.s_store_sk = ss.ss_store_sk
    JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                                 AND sr.sr_item_sk = i.i_item_sk
                                 AND sr.sr_customer_sk = c.c_customer_sk
                                 AND sr.sr_addr_sk = ca.ca_address_sk
                                 AND sr.sr_store_sk = st.s_store_sk
    JOIN tpcds.reason r ON r.r_reason_sk = sr.sr_reason_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                                   AND cr.cr_item_sk = i.i_item_sk
                                   AND cr.cr_refunded_customer_sk = c.c_customer_sk
                                   AND cr.cr_refunded_addr_sk = ca.ca_address_sk
                                   AND cr.cr_call_center_sk = cc.cc_call_center_sk
                                   AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
                                   AND cr.cr_reason_sk = r.r_reason_sk
                                   AND cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
                           AND wp.wp_customer_sk = c.c_customer_sk
    JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                               AND wr.wr_item_sk = i.i_item_sk
                               AND wr.wr_refunded_customer_sk = c.c_customer_sk
                               AND wr.wr_refunded_addr_sk = ca.ca_address_sk
                               AND wr.wr_web_page_sk = wp.wp_web_page_sk
                               AND wr.wr_reason_sk = r.r_reason_sk
    JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND i.i_brand = 'Brand#23'
      AND ca.ca_country = 'United States'
      AND sm.sm_type = 'SHIP'
    GROUP BY d.d_year, i.i_category, r.r_reason_desc, ws.web_tax_percentage
) EXCEPT (
    SELECT
        d.d_year,
        i.i_category,
        r.r_reason_desc,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        COUNT(DISTINCT cs.cs_order_number) AS unique_orders,
        AVG(CASE WHEN cr.cr_return_amount > 0 THEN cr.cr_return_amount END) AS avg_return_amount,
        MIN(ws.web_tax_percentage) AS min_site_tax
    FROM tpcds.date_dim d
    JOIN tpcds.call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
                               AND cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.item i ON i.i_item_sk = cs.cs_item_sk
    JOIN tpcds.customer c ON c.c_customer_sk = cs.cs_bill_customer_sk
    JOIN tpcds.customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
    JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    JOIN tpcds.inventory inv ON inv.inv_date_sk = d.d_date_sk
                              AND inv.inv_item_sk = i.i_item_sk
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
                               AND ss.ss_item_sk = i.i_item_sk
                               AND ss.ss_customer_sk = c.c_customer_sk
                               AND ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.store st ON st.s_store_sk = ss.ss_store_sk
    JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
                                 AND sr.sr_item_sk = i.i_item_sk
                                 AND sr.sr_customer_sk = c.c_customer_sk
                                 AND sr.sr_addr_sk = ca.ca_address_sk
                                 AND sr.sr_store_sk = st.s_store_sk
    JOIN tpcds.reason r ON r.r_reason_sk = sr.sr_reason_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
                                   AND cr.cr_item_sk = i.i_item_sk
                                   AND cr.cr_refunded_customer_sk = c.c_customer_sk
                                   AND cr.cr_refunded_addr_sk = ca.ca_address_sk
                                   AND cr.cr_call_center_sk = cc.cc_call_center_sk
                                   AND cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
                                   AND cr.cr_reason_sk = r.r_reason_sk
                                   AND cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.web_page wp ON wp.wp_creation_date_sk = d.d_date_sk
                           AND wp.wp_customer_sk = c.c_customer_sk
    JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
                               AND wr.wr_item_sk = i.i_item_sk
                               AND wr.wr_refunded_customer_sk = c.c_customer_sk
                               AND wr.wr_refunded_addr_sk = ca.ca_address_sk
                               AND wr.wr_web_page_sk = wp.wp_web_page_sk
                               AND wr.wr_reason_sk = r.r_reason_sk
    JOIN tpcds.web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 1998
    GROUP BY d.d_year, i.i_category, r.r_reason_desc, ws.web_tax_percentage
)
ORDER BY total_store_sales DESC
LIMIT 100
