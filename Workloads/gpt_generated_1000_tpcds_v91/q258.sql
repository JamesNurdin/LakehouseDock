WITH high_spenders AS (
    SELECT DISTINCT cs.cs_bill_customer_sk AS customer_sk
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_net_paid > 2000
      AND cs.cs_ext_tax < 500
      AND cs.cs_list_price > 50
),
union_data AS (
    SELECT 
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_order_number AS order_key,
        cs.cs_ext_tax AS ext_tax,
        cs.cs_list_price AS list_price,
        cp.cp_department AS department,
        sm.sm_type AS ship_type,
        ca.ca_state AS state,
        'catalog' AS channel
    FROM tpcds.catalog_sales cs
    JOIN tpcds.customer c1 ON cs.cs_bill_customer_sk = c1.c_customer_sk
    JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    WHERE cs.cs_net_paid > 2000
      AND cs.cs_ext_tax < 500
      AND ca.ca_state = 'CA'
      AND cp.cp_type = 'Catalog'
    UNION DISTINCT
    SELECT 
        ss.ss_customer_sk AS customer_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_ticket_number AS order_key,
        ss.ss_ext_tax AS ext_tax,
        ss.ss_ext_list_price AS list_price,
        NULL AS department,
        NULL AS ship_type,
        ca2.ca_state AS state,
        'store' AS channel
    FROM tpcds.store_sales ss
    JOIN tpcds.customer c2 ON ss.ss_customer_sk = c2.c_customer_sk
    JOIN tpcds.customer_address ca2 ON ss.ss_addr_sk = ca2.ca_address_sk
    JOIN tpcds.customer_demographics cd2 ON ss.ss_cdemo_sk = cd2.cd_demo_sk
    WHERE ss.ss_net_paid > 2000
      AND ss.ss_ext_tax < 500
      AND ca2.ca_state = 'CA'
),
aggregated AS (
    SELECT 
        u.customer_sk,
        SUM(u.net_paid) AS total_net_paid,
        COUNT(DISTINCT u.order_key) AS total_orders,
        AVG(u.list_price) AS avg_list_price,
        MAX(u.ext_tax) AS max_ext_tax
    FROM union_data u
    GROUP BY u.customer_sk
)
SELECT 
    a.customer_sk,
    c.c_first_name,
    c.c_last_name,
    a.total_net_paid,
    a.total_orders,
    a.avg_list_price,
    a.max_ext_tax,
    ROW_NUMBER() OVER (ORDER BY a.total_net_paid DESC) AS sales_rank
FROM aggregated a
JOIN tpcds.customer c ON a.customer_sk = c.c_customer_sk
WHERE NOT EXISTS (
    SELECT 1
    FROM tpcds.web_returns wr
    WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
)
  AND a.customer_sk IN (SELECT customer_sk FROM high_spenders)
ORDER BY a.total_net_paid DESC
LIMIT 100
