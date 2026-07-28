WITH
    -- Alias date dimensions for sold and ship dates
    d_sold AS (
        SELECT *
        FROM date_dim
        WHERE d_year = 2000
    ),
    d_ship AS (
        SELECT *
        FROM date_dim
    )
SELECT
    d_sold.d_year,
    cc.cc_name,
    sm.sm_carrier,
    cust_bill.c_last_name,
    SUM(cs.cs_net_paid)               AS total_net_paid,
    SUM(cs.cs_ext_sales_price)        AS total_sales,
    COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
    SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amt
FROM catalog_sales cs
JOIN d_sold               ON cs.cs_sold_date_sk   = d_sold.d_date_sk
JOIN d_ship               ON cs.cs_ship_date_sk   = d_ship.d_date_sk
JOIN customer cust_bill   ON cs.cs_bill_customer_sk = cust_bill.c_customer_sk
JOIN customer cust_ship   ON cs.cs_ship_customer_sk = cust_ship.c_customer_sk
JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN call_center cc       ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm         ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
JOIN warehouse w          ON cs.cs_warehouse_sk   = w.w_warehouse_sk
JOIN inventory inv        ON inv.inv_warehouse_sk = w.w_warehouse_sk
                           AND inv.inv_date_sk     = d_sold.d_date_sk
JOIN store s              ON s.s_closed_date_sk  = d_ship.d_date_sk
LEFT JOIN web_returns wr ON wr.wr_returned_date_sk = d_sold.d_date_sk
                           AND wr.wr_refunded_customer_sk = cust_bill.c_customer_sk
LEFT JOIN reason r        ON wr.wr_reason_sk = r.r_reason_sk
LEFT JOIN web_page wp     ON wr.wr_web_page_sk = wp.wp_web_page_sk
WHERE sm.sm_carrier = 'USPS'
GROUP BY ROLLUP (d_sold.d_year, cc.cc_name, sm.sm_carrier, cust_bill.c_last_name)
ORDER BY d_sold.d_year DESC, total_net_paid DESC
LIMIT 100
