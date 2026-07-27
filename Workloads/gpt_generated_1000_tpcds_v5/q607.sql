WITH filtered_pages AS (
        SELECT
            cp_catalog_page_sk,
            cp_department,
            cp_description,
            cp_type
        FROM catalog_page
        WHERE regexp_like(cp_description, '[A-Z]{2}[0-9]{2}')
    ),
    sales_agg AS (
        SELECT
            cs.cs_call_center_sk AS call_center_sk,
            cs.cs_catalog_page_sk AS catalog_page_sk,
            SUM(cs.cs_net_profit) AS total_profit,
            COUNT(*) AS sales_cnt
        FROM catalog_sales cs
        JOIN filtered_pages fp ON cs.cs_catalog_page_sk = fp.cp_catalog_page_sk
        JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
        WHERE td.t_shift = 'first'
        GROUP BY cs.cs_call_center_sk, cs.cs_catalog_page_sk
    )
SELECT
    cc.cc_name,
    fp.cp_department,
    fp.cp_type,
    sa.total_profit,
    sa.sales_cnt,
    CONCAT(cc.cc_city, ', ', cc.cc_state) AS location,
    SUBSTRING(cc.cc_manager FROM 1 FOR 5) AS manager_prefix
FROM sales_agg sa
JOIN call_center cc ON sa.call_center_sk = cc.cc_call_center_sk
JOIN filtered_pages fp ON sa.catalog_page_sk = fp.cp_catalog_page_sk
WHERE cc.cc_name LIKE 'Call%Center%'
ORDER BY sa.total_profit DESC
LIMIT 100
