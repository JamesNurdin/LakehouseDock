WITH sales_agg AS (
    SELECT
        ss_addr_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        AVG(ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS txn_cnt,
        CASE WHEN SUM(ss_ext_sales_price) > 50000 THEN 'HIGH' ELSE 'LOW' END AS sales_band
    FROM store_sales
    WHERE ss_item_sk IN (
        SELECT ss_item_sk
        FROM store_sales
        WHERE ss_ext_discount_amt > 1000
    )
    GROUP BY ss_addr_sk
),
addr_key_state AS (
    SELECT ca_address_sk
    FROM customer_address
    WHERE ca_state = 'CA'
),
addr_key_cost AS (
    SELECT ss_addr_sk
    FROM store_sales
    WHERE ss_wholesale_cost > 80
),
intersect_keys AS (
    SELECT ca_address_sk FROM addr_key_state
    INTERSECT
    SELECT ss_addr_sk FROM addr_key_cost
)
SELECT
    ca.ca_address_id,
    ca.ca_city,
    ca.ca_state,
    COALESCE(sa.total_sales, 0) AS total_sales,
    sa.sales_band,
    sa.txn_cnt,
    sa.avg_discount
FROM sales_agg sa
RIGHT OUTER JOIN customer_address ca
    ON sa.ss_addr_sk = ca.ca_address_sk
WHERE ca.ca_address_sk IN (SELECT ca_address_sk FROM intersect_keys)
  AND ca.ca_country = 'United States'
  AND ca.ca_gmt_offset BETWEEN -5.00 AND 5.00
  AND ca.ca_street_type IN ('Road', 'Ave')
ORDER BY total_sales DESC
OFFSET 0 FETCH FIRST 100 ROWS ONLY
