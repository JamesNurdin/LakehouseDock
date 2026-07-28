WITH filtered_sales AS (
    SELECT
        cs.cs_item_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_ship_mode_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        cp.cp_department,
        cp.cp_description,
        i.i_brand,
        i.i_item_desc,
        w.w_warehouse_name,
        sm.sm_type,
        ca.ca_city
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(cp.cp_description, '^A.*')
      AND regexp_like(i.i_item_desc, '(?i)metal')
      AND ca.ca_city LIKE 'San %'
)
SELECT
    i_brand,
    cp_department,
    sm_type,
    w_warehouse_name,
    REGEXP_EXTRACT(i_item_desc, '(\\d{4})', 1) AS item_code,
    SUM(cs_quantity) AS total_quantity,
    SUM(cs_net_profit) AS total_profit,
    COUNT(*) AS sales_transactions,
    CONCAT('Dept-', cp_department) AS dept_label,
    SUBSTR(cp_description, 1, 10) AS short_desc
FROM filtered_sales
GROUP BY
    i_brand,
    cp_department,
    sm_type,
    w_warehouse_name,
    REGEXP_EXTRACT(i_item_desc, '(\\d{4})', 1),
    CONCAT('Dept-', cp_department),
    SUBSTR(cp_description, 1, 10)
ORDER BY total_profit DESC
LIMIT 100
