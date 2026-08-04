-- Goal: Analyze sales performance by catalog number and customer state, showing subtotals and a grand total, ranking catalogs within each state, and classifying sales levels.
WITH joined_data AS (
    SELECT
        cp.cp_catalog_number,
        ca.ca_state,
        cs.cs_ext_sales_price,
        ss.ss_ext_sales_price,
        cs.cs_net_paid_inc_tax
    FROM catalog_page cp
    JOIN catalog_sales cs
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN store_sales ss
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE cp.cp_catalog_number IN (1, 20, 13)
      AND ca.ca_location_type = 'apartment'
      AND ss.ss_ext_sales_price > 1000
      AND cs.cs_net_paid_inc_tax > 500
),
aggregated AS (
    SELECT
        cp_catalog_number,
        ca_state,
        SUM(cs_ext_sales_price) AS catalog_sales_total,
        SUM(ss_ext_sales_price) AS store_sales_total,
        SUM(cs_ext_sales_price + ss_ext_sales_price) AS total_sales
    FROM joined_data
    GROUP BY ROLLUP (cp_catalog_number, ca_state)
)
SELECT
    cp_catalog_number,
    ca_state,
    catalog_sales_total,
    store_sales_total,
    total_sales,
    CASE WHEN total_sales > 10000 THEN 'high' ELSE 'medium' END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY cp_catalog_number ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
ORDER BY
    CASE WHEN cp_catalog_number IS NULL THEN 1 ELSE 0 END,  -- puts grand total last
    cp_catalog_number,
    ca_state
LIMIT 100
