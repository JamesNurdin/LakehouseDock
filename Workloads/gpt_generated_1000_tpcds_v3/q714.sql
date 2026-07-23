WITH sales_by_center AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_suite_number,
        cc.cc_city,
        cc.cc_state,
        ca.ca_city AS bill_city,
        ca.ca_state AS bill_state,
        ca.ca_suite_number AS bill_suite,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(cs.cs_ext_sales_price) AS total_ext_sales,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE
        regexp_like(cc.cc_suite_number, '^Suite [A-Z]+$')
        AND ca.ca_country = 'United States'
        AND cs.cs_list_price > 100
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_suite_number,
        cc.cc_city,
        cc.cc_state,
        ca.ca_city,
        ca.ca_state,
        ca.ca_suite_number
)
SELECT
    cc_name,
    cc_suite_number,
    CONCAT(cc_city, ', ', cc_state) AS center_location,
    bill_city,
    bill_state,
    total_net_paid,
    total_ext_sales,
    sales_cnt,
    CASE
        WHEN total_net_paid >= 100000 THEN 'Very High'
        WHEN total_net_paid >= 50000 THEN 'High'
        ELSE 'Medium'
    END AS net_paid_bucket,
    regexp_extract(cc_suite_number, '[0-9]+') AS suite_number_numeric,
    RANK() OVER (ORDER BY total_net_paid DESC) AS net_paid_rank
FROM sales_by_center
WHERE bill_city LIKE 'A%'
ORDER BY total_net_paid DESC
LIMIT 100
