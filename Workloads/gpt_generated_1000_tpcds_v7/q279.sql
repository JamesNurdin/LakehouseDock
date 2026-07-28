WITH
    -- Base sales with its date dimension
    sales AS (
        SELECT
            ss.ss_sold_date_sk,
            ss.ss_customer_sk,
            ss.ss_net_profit,
            d1.d_year
        FROM tpcds.store_sales ss
        JOIN tpcds.date_dim d1
            ON ss.ss_sold_date_sk = d1.d_date_sk
    ),
    -- Catalog returns linked to the same date dimension and call center / ship mode
    cat_ret AS (
        SELECT
            cr.cr_return_amount,
            cr.cr_call_center_sk,
            cr.cr_ship_mode_sk,
            cr.cr_returned_date_sk
        FROM tpcds.catalog_returns cr
        JOIN tpcds.date_dim d2
            ON cr.cr_returned_date_sk = d2.d_date_sk
    ),
    -- Web returns linked to the same date dimension
    web_ret AS (
        SELECT
            wr.wr_return_amt,
            wr.wr_returned_date_sk
        FROM tpcds.web_returns wr
        JOIN tpcds.date_dim d3
            ON wr.wr_returned_date_sk = d3.d_date_sk
    ),
    -- Inventory linked through a second date‑dimension alias
    inv AS (
        SELECT
            inv.inv_quantity_on_hand,
            inv.inv_date_sk
        FROM tpcds.inventory inv
        JOIN tpcds.date_dim d4
            ON inv.inv_date_sk = d4.d_date_sk
    )
SELECT
    d1.d_year,
    cc.cc_name,
    SUM(s.ss_net_profit)                           AS total_sales_profit,
    SUM(cr.cr_return_amount)                       AS total_catalog_returns,
    SUM(wr.wr_return_amt)                          AS total_web_returns,
    SUM(i.inv_quantity_on_hand)                    AS total_inventory_on_hand,
    COUNT(DISTINCT s.ss_customer_sk)               AS distinct_customers
FROM tpcds.store_sales s
JOIN tpcds.date_dim d1
    ON s.ss_sold_date_sk = d1.d_date_sk
JOIN tpcds.customer_demographics cd
    ON s.ss_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
    ON s.ss_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.customer_address ca
    ON s.ss_addr_sk = ca.ca_address_sk
JOIN tpcds.catalog_returns cr
    ON cr.cr_returned_date_sk = d1.d_date_sk
JOIN tpcds.call_center cc
    ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.web_returns wr
    ON wr.wr_returned_date_sk = d1.d_date_sk
JOIN tpcds.web_site ws
    ON ws.web_open_date_sk = d1.d_date_sk
JOIN tpcds.date_dim d2  -- second alias for date_dim
    ON d2.d_date_sk = ws.web_close_date_sk
JOIN tpcds.inventory i
    ON i.inv_date_sk = d2.d_date_sk
GROUP BY
    d1.d_year,
    cc.cc_name
ORDER BY
    d1.d_year DESC,
    total_sales_profit DESC
