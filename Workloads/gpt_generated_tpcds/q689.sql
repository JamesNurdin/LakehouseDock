WITH sales_by_address AS (
    SELECT
        ca_state,
        ca_city,
        ca_location_type,
        store_sales.ss_net_paid,
        store_sales.ss_net_profit,
        store_sales.ss_quantity,
        store_sales.ss_ext_discount_amt
    FROM store_sales
    JOIN customer_address
        ON store_sales.ss_addr_sk = customer_address.ca_address_sk
    WHERE customer_address.ca_country = 'United States'
      AND store_sales.ss_store_sk = 1
)
SELECT
    ca_state,
    ca_city,
    ca_location_type,
    sum(ss_net_paid) AS total_sales,
    sum(ss_net_profit) AS total_profit,
    sum(ss_quantity) AS total_quantity,
    sum(ss_ext_discount_amt) AS total_discount,
    avg(ss_ext_discount_amt) AS avg_discount_amount
FROM sales_by_address
GROUP BY
    ca_state,
    ca_city,
    ca_location_type
ORDER BY total_sales DESC
LIMIT 10
