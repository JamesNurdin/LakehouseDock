WITH sales_union AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cp.cp_catalog_number,
        cp.cp_department,
        td.t_hour,
        ca.ca_state,
        ca.ca_location_type,
        ca.ca_address_sk,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cp.cp_catalog_number = 14
      AND ca.ca_state = 'TX'
      AND td.t_hour >= 8

    UNION DISTINCT

    SELECT
        cs.cs_sold_date_sk,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cp.cp_catalog_number,
        cp.cp_department,
        td.t_hour,
        ca.ca_state,
        ca.ca_location_type,
        ca.ca_address_sk,
        cs.cs_bill_customer_sk
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cp.cp_catalog_number = 5
      AND ca.ca_state = 'AZ'
      AND td.t_hour < 4
)
SELECT
    su.cs_sold_date_sk,
    su.cp_catalog_number,
    su.cp_department,
    su.t_hour,
    su.ca_state,
    su.ca_location_type,
    su.cs_ext_sales_price,
    CASE WHEN su.cp_department = 'Books' THEN 'Books' ELSE 'Other' END AS dept_group,
    addr.addr_total,
    ROW_NUMBER() OVER (PARTITION BY su.ca_state ORDER BY addr.addr_total DESC) AS rn_state
FROM sales_union su
LEFT JOIN LATERAL (
    SELECT sum(cs2.cs_ext_sales_price) AS addr_total
    FROM catalog_sales cs2
    WHERE cs2.cs_bill_addr_sk = su.ca_address_sk
) AS addr ON true
WHERE EXISTS (
    SELECT 1
    FROM customer_address ca2
    WHERE ca2.ca_address_sk = su.ca_address_sk
      AND ca2.ca_location_type = 'apartment'
)
ORDER BY su.ca_state, rn_state
LIMIT 100
