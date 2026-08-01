WITH joined_data AS (
    SELECT
        d.d_year,
        s.s_store_name,
        s.s_state,
        cc.cc_name,
        sm.sm_type,
        cs.cs_net_paid,
        sr.sr_return_amt,
        c.c_customer_sk,
        cs.cs_quantity,
        cs.cs_ext_discount_amt
    FROM tpcds.date_dim d
    JOIN tpcds.store_returns sr ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
    JOIN tpcds.customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN tpcds.catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND ca.ca_street_name = 'Pine Oak'
      AND cc.cc_name = 'Call Center 1'
      AND sm.sm_type = 'Express'
)
SELECT
    d_year,
    s_store_name,
    cc_name,
    sm_type,
    SUM(cs_net_paid) AS total_net_paid,
    SUM(sr_return_amt) AS total_return_amount,
    COUNT(DISTINCT c_customer_sk) AS distinct_customers,
    AVG(cs_quantity) AS avg_quantity,
    MIN(cs_ext_discount_amt) AS min_discount,
    MAX(cs_ext_discount_amt) AS max_discount
FROM joined_data
GROUP BY d_year, s_store_name, cc_name, sm_type
HAVING SUM(cs_net_paid) > 100000
   AND COUNT(DISTINCT c_customer_sk) > 5
ORDER BY total_net_paid DESC
LIMIT 100
