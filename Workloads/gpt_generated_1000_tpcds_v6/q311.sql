WITH sales_data AS (
    SELECT
        cc.cc_name,
        concat(cc.cc_city, ', ', cc.cc_state) AS location,
        cp.cp_department,
        cs.cs_net_paid,
        cs.cs_net_profit,
        td.t_hour
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE regexp_like(cc.cc_name, '^A.*')
      AND cc.cc_suite_number LIKE 'Suite %'
      AND regexp_like(cp.cp_description, '(?i)fresh')
      AND td.t_hour BETWEEN 9 AND 17
)
SELECT
    cc_name,
    location,
    cp_department,
    sum(cs_net_paid) AS total_net_paid,
    sum(cs_net_profit) AS total_net_profit,
    count(*) AS sales_count
FROM sales_data
GROUP BY cc_name, location, cp_department
ORDER BY total_net_paid DESC
LIMIT 100
