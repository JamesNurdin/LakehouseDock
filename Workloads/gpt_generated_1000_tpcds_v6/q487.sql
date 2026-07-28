WITH sales_data AS (
    SELECT
        d.d_year,
        t.t_am_pm,
        i.i_brand,
        i.i_item_id,
        ca.ca_state,
        sm.sm_carrier,
        p.p_promo_name,
        cs.cs_order_number,
        cs.cs_quantity,
        cs.cs_net_paid,
        ws.ws_net_paid,
        cr.cr_return_amount,
        wr.wr_return_amt,
        sr.sr_return_amt,
        c.c_customer_sk
    FROM tpcds.date_dim d
    JOIN tpcds.store_returns sr
        ON d.d_date_sk = sr.sr_returned_date_sk
    JOIN tpcds.time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN tpcds.item i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN tpcds.customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.customer_address ca
        ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN tpcds.catalog_returns cr
        ON i.i_item_sk = cr.cr_item_sk
    JOIN tpcds.catalog_sales cs
        ON cr.cr_order_number = cs.cs_order_number
    JOIN tpcds.promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.inventory inv
        ON i.i_item_sk = inv.inv_item_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN tpcds.web_sales ws
        ON wp.wp_web_page_sk = ws.ws_web_page_sk
    JOIN tpcds.web_returns wr
        ON wp.wp_web_page_sk = wr.wr_web_page_sk
    WHERE
        d.d_year = 2001
        AND t.t_am_pm = 'PM'
        AND i.i_brand = 'Brand#45'
        AND ca.ca_state = 'CA'
        AND sm.sm_carrier = 'USPS'
        AND p.p_discount_active = 'Y'
        AND cs.cs_quantity > 10
        AND EXISTS (
            SELECT 1
            FROM tpcds.web_returns wr2
            WHERE wr2.wr_refunded_customer_sk = c.c_customer_sk
              AND wr2.wr_return_amt > 100
        )
)
SELECT
    d_year,
    i_brand,
    sm_carrier,
    SUM(cs_net_paid) AS total_catalog_sales,
    SUM(ws_net_paid) AS total_web_sales,
    SUM(cr_return_amount) AS total_catalog_returns,
    SUM(wr_return_amt) AS total_web_returns,
    SUM(sr_return_amt) AS total_store_returns,
    COUNT(DISTINCT cs_order_number) AS distinct_orders
FROM sales_data
GROUP BY ROLLUP (d_year, i_brand, sm_carrier)
HAVING SUM(cs_net_paid) + SUM(ws_net_paid) > 10000
ORDER BY d_year, i_brand, sm_carrier
LIMIT 100
