WITH base AS (
    SELECT
        d.d_year AS d_year,
        i.i_category AS i_category,
        sm.sm_type AS sm_type,
        p.p_promo_name AS promo_name,
        r.r_reason_desc AS reason_desc,
        cs.cs_net_paid AS cs_net_paid,
        ss.ss_net_paid AS ss_net_paid,
        wr.wr_return_amt AS wr_return_amt,
        cs.cs_order_number AS cs_order_number,
        ss.ss_ticket_number AS ss_ticket_number,
        wr.wr_order_number AS wr_order_number
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
       AND ss.ss_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
    LEFT JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    LEFT JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    LEFT JOIN web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
       AND wr.wr_item_sk = i.i_item_sk
    LEFT JOIN customer_address ca_wr_refunded ON wr.wr_refunded_addr_sk = ca_wr_refunded.ca_address_sk
    LEFT JOIN customer_address ca_wr_returning ON wr.wr_returning_addr_sk = ca_wr_returning.ca_address_sk
    LEFT JOIN customer_demographics cd_wr_refunded ON wr.wr_refunded_cdemo_sk = cd_wr_refunded.cd_demo_sk
    LEFT JOIN customer_demographics cd_wr_returning ON wr.wr_returning_cdemo_sk = cd_wr_returning.cd_demo_sk
    LEFT JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d_wp_creation ON wp.wp_creation_date_sk = d_wp_creation.d_date_sk
    LEFT JOIN date_dim d_wp_access ON wp.wp_access_date_sk = d_wp_access.d_date_sk
)
SELECT
    d_year,
    i_category,
    sm_type,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ss_net_paid) AS total_store_sales,
    SUM(wr_return_amt) AS total_web_returns,
    COUNT(DISTINCT cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ss_ticket_number) AS store_tickets,
    COUNT(DISTINCT wr_order_number) AS web_return_orders
FROM base
GROUP BY ROLLUP (d_year, i_category, sm_type)
HAVING SUM(cs_net_paid) > 1000000
ORDER BY d_year, i_category, sm_type
