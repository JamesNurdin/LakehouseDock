WITH sales_by_warehouse AS (
    SELECT
        w.w_warehouse_name,
        w.w_city,
        cp.cp_department,
        cp.cp_type,
        cp.cp_description,
        SUM(cs.cs_net_paid) AS total_net_paid
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE regexp_like(cp.cp_description, '.*[0-9]{2}.*')
      AND ca.ca_city LIKE '%York%'
    GROUP BY
        w.w_warehouse_name,
        w.w_city,
        cp.cp_department,
        cp.cp_type,
        cp.cp_description
)
SELECT
    warehouse_name,
    department,
    total_net_paid,
    regexp_extract(description, '(\\w+)', 1) AS first_word_desc,
    concat(city, '-', type) AS warehouse_type_concat,
    SUM(total_net_paid) OVER (
        PARTITION BY warehouse_name
        ORDER BY total_net_paid DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total_net_paid
FROM (
    SELECT
        w_warehouse_name AS warehouse_name,
        w_city AS city,
        cp_department AS department,
        cp_type AS type,
        cp_description AS description,
        total_net_paid
    FROM sales_by_warehouse
) sub
ORDER BY running_total_net_paid DESC
LIMIT 100
