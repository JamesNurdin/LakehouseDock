WITH filtered_sales AS (
        SELECT
            ca.ca_address_sk,
            ca.ca_address_id,
            ca.ca_city,
            ca.ca_county,
            SUM(ss.ss_ext_sales_price) AS total_sales,
            AVG(ss.ss_ext_discount_amt) AS avg_discount,
            COUNT(DISTINCT ss.ss_ticket_number) AS unique_tickets
        FROM store_sales ss
        JOIN customer_address ca
          ON ss.ss_addr_sk = ca.ca_address_sk
        WHERE ca.ca_gmt_offset = -5.00                     -- predicate 1
          AND ca.ca_county IN ('Williams County', 'Chelan County')   -- predicate 2
          AND ss.ss_item_sk IN (170084, 285752)           -- predicate 3
          AND ss.ss_ext_discount_amt > 1000              -- predicate 4
        GROUP BY ca.ca_address_sk, ca.ca_address_id, ca.ca_city, ca.ca_county
    ),
    high_sales AS (
        SELECT ca_address_id
        FROM filtered_sales
        WHERE total_sales > 20000
    ),
    excluded AS (
        SELECT ca_address_id
        FROM filtered_sales
        WHERE ca_city = 'Springfield'
    )
SELECT DISTINCT
    fs.ca_address_id,
    fs.ca_city,
    fs.ca_county,
    fs.total_sales,
    fs.avg_discount,
    fs.unique_tickets,
    ROW_NUMBER() OVER (PARTITION BY fs.ca_county ORDER BY fs.total_sales DESC) AS rn
FROM filtered_sales fs
WHERE fs.ca_address_id IN (
        SELECT ca_address_id FROM high_sales
        EXCEPT
        SELECT ca_address_id FROM excluded
    )
  AND EXISTS (
        SELECT 1
        FROM store_sales s2
        WHERE s2.ss_addr_sk = fs.ca_address_sk
          AND s2.ss_ext_discount_amt > 2000
    )
ORDER BY fs.total_sales DESC, rn
