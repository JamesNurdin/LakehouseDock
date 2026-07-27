WITH high_qty_sales AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_addr_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
)
SELECT
    ca.ca_state,
    ca.ca_city,
    COUNT(DISTINCT ss.ss_ticket_number) AS unique_tickets,
    SUM(ss.ss_ext_sales_price) AS total_store_sales,
    AVG(ss.ss_quantity) AS avg_quantity,
    CASE WHEN AVG(ss.ss_quantity) > 5 THEN 'High Avg Qty' ELSE 'Low Avg Qty' END AS quantity_level,
    (
        SELECT MAX(total_sales)
        FROM (
            SELECT SUM(cs.cs_ext_sales_price) AS total_sales
            FROM catalog_sales cs
            GROUP BY cs.cs_call_center_sk
        ) t
    ) AS max_call_center_sales
FROM store_sales ss
JOIN customer_address ca
    ON ss.ss_addr_sk = ca.ca_address_sk
WHERE
    ca.ca_state = 'CA'
    AND ca.ca_city = 'Los Angeles'
    AND ca.ca_suite_number LIKE 'Suite %'
    AND ss.ss_sales_price > 100
    AND EXISTS (
        SELECT 1
        FROM high_qty_sales hqs
        JOIN call_center cc
            ON hqs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp
            ON hqs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        WHERE hqs.cs_bill_addr_sk = ca.ca_address_sk
          AND cc.cc_country = 'United States'
          AND cp.cp_department = 'Electronics'
    )
GROUP BY ca.ca_state, ca.ca_city
ORDER BY total_store_sales DESC
LIMIT 100
