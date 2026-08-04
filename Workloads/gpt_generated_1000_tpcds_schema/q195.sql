WITH
joined_all AS (
    SELECT
        ss.ss_ticket_number,
        cs.cs_order_number,
        sr.sr_ticket_number AS sr_ticket,
        cr.cr_order_number AS cr_order,
        d_sold.d_year,
        cc.cc_name,
        cp.cp_type,
        inv.inv_quantity_on_hand,
        wp.wp_url,
        ws.web_name,
        ca_bill.ca_city AS bill_city,
        ca_ship.ca_city AS ship_city,
        cd_bill.cd_gender AS bill_gender,
        cd_ship.cd_gender AS ship_gender,
        hd_bill.hd_income_band_sk AS bill_income_band,
        hd_ship.hd_income_band_sk AS ship_income_band,
        ss.ss_net_profit,
        cs.cs_net_paid
    FROM store_sales ss
    JOIN date_dim d_sold
        ON ss.ss_sold_date_sk = d_sold.d_date_sk
    JOIN customer c_bill
        ON ss.ss_customer_sk = c_bill.c_customer_sk
    JOIN customer_address ca_bill
        ON ss.ss_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_bill
        ON ss.ss_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill
        ON ss.ss_hdemo_sk = hd_bill.hd_demo_sk
    -- catalog_sales joins (both ship and bill dimensions)
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN customer c_ship
        ON cs.cs_ship_customer_sk = c_ship.c_customer_sk
    JOIN customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_ship
        ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship
        ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer c_bill2
        ON cs.cs_bill_customer_sk = c_bill2.c_customer_sk
    JOIN customer_address ca_bill2
        ON cs.cs_bill_addr_sk = ca_bill2.ca_address_sk
    JOIN customer_demographics cd_bill2
        ON cs.cs_bill_cdemo_sk = cd_bill2.cd_demo_sk
    JOIN household_demographics hd_bill2
        ON cs.cs_bill_hdemo_sk = hd_bill2.hd_demo_sk
    -- call center and catalog page
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    -- inventory (by date)
    JOIN inventory inv
        ON inv.inv_date_sk = d_sold.d_date_sk
    -- catalog returns (by order number)
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN date_dim d_cr
        ON cr.cr_returned_date_sk = d_cr.d_date_sk
    -- store returns (by ticket number)
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN date_dim d_sr
        ON sr.sr_returned_date_sk = d_sr.d_date_sk
    -- web page (by customer) and its date dimensions
    JOIN web_page wp
        ON wp.wp_customer_sk = c_bill.c_customer_sk
    JOIN date_dim d_wp_creation
        ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_wp_access
        ON wp.wp_access_date_sk = d_wp_access.d_date_sk
    -- web site (by its open date)
    JOIN web_site ws
        ON ws.web_open_date_sk = d_wp_creation.d_date_sk
    JOIN date_dim d_ws_open
        ON ws.web_open_date_sk = d_ws_open.d_date_sk
    WHERE d_sold.d_year = 2001
)
SELECT
    d_year,
    cc_name,
    cp_type,
    COUNT(DISTINCT ss_ticket_number) AS store_sales_orders,
    SUM(ss_net_profit) AS total_store_profit,
    SUM(cs_net_paid) AS total_catalog_sales,
    COUNT(*) FILTER (WHERE sr_ticket IS NOT NULL) AS returned_orders,
    (
        SELECT COUNT(*)
        FROM (
            SELECT ss_ticket_number
            FROM store_sales ss2
            JOIN date_dim d2 ON ss2.ss_sold_date_sk = d2.d_date_sk
            WHERE d2.d_year = 2001
            INTERSECT
            SELECT cs_order_number
            FROM catalog_sales cs2
            JOIN date_dim d3 ON cs2.cs_sold_date_sk = d3.d_date_sk
            WHERE d3.d_year = 2001
        ) intersected
        EXCEPT
        SELECT sr_ticket_number
        FROM store_returns sr2
        JOIN date_dim d4 ON sr2.sr_returned_date_sk = d4.d_date_sk
        WHERE d4.d_year = 2001
    ) AS intersect_minus_returns
FROM joined_all
GROUP BY d_year, cc_name, cp_type
ORDER BY total_store_profit DESC
LIMIT 100
