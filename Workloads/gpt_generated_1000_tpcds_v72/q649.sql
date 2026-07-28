WITH filtered_sales AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_customer_sk,
        cs.cs_net_profit,
        cs.cs_ext_tax,
        cs.cs_ext_ship_cost
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.customer cu
        ON cs.cs_bill_customer_sk = cu.c_customer_sk
    JOIN tpcds.web_page wp
        ON wp.wp_customer_sk = cu.c_customer_sk
    WHERE
        regexp_like(cp.cp_description, '(?i)store')
        AND cp.cp_description LIKE '%new%'
        AND wp.wp_url LIKE '%http%'
        AND substr(cu.c_last_name, 1, 1) = 'S'
)
SELECT
    cc.cc_name,
    cp.cp_catalog_number,
    COUNT(DISTINCT f.cs_bill_customer_sk) AS distinct_customers,
    SUM(f.cs_net_profit) AS total_net_profit,
    SUM(f.cs_ext_tax) AS total_tax,
    CASE
        WHEN SUM(f.cs_net_profit) > 0 THEN 'POSITIVE'
        ELSE 'NON_POSITIVE'
    END AS profit_flag,
    concat(cc.cc_name, ' - ', cp.cp_description) AS combined_desc
FROM filtered_sales f
JOIN tpcds.call_center cc
    ON f.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON f.cs_catalog_page_sk = cp.cp_catalog_page_sk
GROUP BY
    cc.cc_name,
    cp.cp_catalog_number,
    cp.cp_description
ORDER BY total_net_profit DESC
LIMIT 100
