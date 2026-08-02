WITH ss_agg AS (
    SELECT
        ss_sold_date_sk,
        ss_hdemo_sk,
        ss_addr_sk,
        SUM(ss_net_paid) AS total_net_paid,
        SUM(ss_quantity) AS total_quantity,
        COUNT(*) AS sales_txn_cnt
    FROM store_sales
    GROUP BY ss_sold_date_sk, ss_hdemo_sk, ss_addr_sk
), join_agg AS (
    SELECT
        cc.cc_name,
        ws_site.web_name,
        d_sold.d_year,
        hd_ss.hd_buy_potential,
        SUM(ss_agg.total_net_paid) AS agg_total_net_paid,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt
    FROM ss_agg
    JOIN date_dim d_sold
        ON ss_agg.ss_sold_date_sk = d_sold.d_date_sk
    JOIN household_demographics hd_ss
        ON ss_agg.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN customer_address ca_ss
        ON ss_agg.ss_addr_sk = ca_ss.ca_address_sk
    JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d_sold.d_date_sk
    JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w_cr
        ON cr.cr_warehouse_sk = w_cr.w_warehouse_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN household_demographics hd_ws_bill
        ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN household_demographics hd_ws_ship
        ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    JOIN customer_address ca_ws_bill
        ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer_address ca_ws_ship
        ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    JOIN web_site ws_site
        ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN warehouse w_ws
        ON ws.ws_warehouse_sk = w_ws.w_warehouse_sk
    JOIN date_dim d_site_open
        ON ws_site.web_open_date_sk = d_site_open.d_date_sk
    JOIN date_dim d_site_close
        ON ws_site.web_close_date_sk = d_site_close.d_date_sk
    WHERE ss_agg.ss_sold_date_sk NOT IN (
        SELECT cr2.cr_returned_date_sk
        FROM catalog_returns cr2
        WHERE cr2.cr_return_quantity > 0
    )
    GROUP BY cc.cc_name, ws_site.web_name, d_sold.d_year, hd_ss.hd_buy_potential
)
SELECT
    j.cc_name,
    j.web_name,
    j.d_year,
    j.hd_buy_potential,
    j.agg_total_net_paid,
    j.total_return_amount,
    j.web_order_cnt,
    ROW_NUMBER() OVER (PARTITION BY j.cc_name ORDER BY j.agg_total_net_paid DESC) AS sales_rank
FROM join_agg j
ORDER BY j.agg_total_net_paid DESC
LIMIT 100
