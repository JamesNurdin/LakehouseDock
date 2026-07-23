SELECT
    concat(cc.cc_city, ', ', cc.cc_state) AS call_center_location,
    regexp_extract(cc.cc_name, '(\\w+) Center', 1) AS center_type,
    substring(cc.cc_name, 1, 5) AS name_prefix,
    sum(cs.cs_ext_sales_price) AS total_sales,
    count(DISTINCT cs.cs_order_number) AS order_count,
    CASE
        WHEN sum(cs.cs_ext_sales_price) > 2000 THEN 'high'
        WHEN sum(cs.cs_ext_sales_price) > 1000 THEN 'medium'
        ELSE 'low'
    END AS sales_category
FROM tpcds.catalog_sales cs
INNER JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
INNER JOIN tpcds.time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
INNER JOIN tpcds.customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
WHERE
    t.t_hour BETWEEN 8 AND 10
    AND regexp_like(cc.cc_name, 'Center$')
    AND ca.ca_address_id LIKE 'AAAAAAA%'
GROUP BY
    concat(cc.cc_city, ', ', cc.cc_state),
    regexp_extract(cc.cc_name, '(\\w+) Center', 1),
    substring(cc.cc_name, 1, 5)
ORDER BY total_sales DESC
LIMIT 100
