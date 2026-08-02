WITH filtered_addresses AS (
    SELECT DISTINCT ca_address_sk, ca_suite_number, ca_location_type, ca_state
    FROM customer_address
    WHERE ca_location_type = 'condo'
      AND ca_suite_number = 'Suite 130'
),
aggregated AS (
    SELECT
        call_center.cc_name,
        ship_mode.sm_type,
        SUM(catalog_sales.cs_ext_sales_price) AS total_sales,
        AVG(catalog_sales.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT catalog_sales.cs_order_number) AS distinct_orders,
        MIN(catalog_sales.cs_sold_date_sk) AS min_sold_date_sk
    FROM catalog_sales
    INNER JOIN call_center
        ON catalog_sales.cs_call_center_sk = call_center.cc_call_center_sk
    INNER JOIN catalog_page
        ON catalog_sales.cs_catalog_page_sk = catalog_page.cp_catalog_page_sk
    LEFT JOIN ship_mode
        ON catalog_sales.cs_ship_mode_sk = ship_mode.sm_ship_mode_sk
    INNER JOIN filtered_addresses
        ON catalog_sales.cs_bill_addr_sk = filtered_addresses.ca_address_sk
    WHERE
        catalog_sales.cs_ext_list_price > 1000
        AND catalog_sales.cs_quantity >= 2
        AND catalog_sales.cs_wholesale_cost BETWEEN 20 AND 50
        AND call_center.cc_state = 'CA'
        AND (ship_mode.sm_contract IN ('yVfotg7Tio3MVhBg6Bkn', 'Xjy3ZPuiDjzHlRx14Z3') OR ship_mode.sm_contract IS NULL)
        AND catalog_sales.cs_call_center_sk IN (
            SELECT cc_call_center_sk FROM call_center WHERE cc_state = 'CA'
        )
        AND catalog_sales.cs_ext_discount_amt > (
            SELECT AVG(cs_ext_discount_amt) FROM catalog_sales
        )
    GROUP BY ROLLUP (call_center.cc_name, ship_mode.sm_type)
    HAVING SUM(catalog_sales.cs_ext_sales_price) > 50000
)
SELECT
    cc_name,
    sm_type,
    total_sales,
    avg_discount,
    distinct_orders,
    min_sold_date_sk,
    ROW_NUMBER() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
