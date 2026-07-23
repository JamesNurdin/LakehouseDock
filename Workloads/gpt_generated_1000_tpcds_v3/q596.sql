WITH filtered_items AS (
    SELECT DISTINCT i_item_sk,
           i_product_name,
           i_category,
           i_brand,
           i_color
    FROM item
    WHERE regexp_like(i_product_name, '\\d{3}-[A-Z]+')
      AND i_product_name LIKE '%Premium%'
)
SELECT
    CONCAT(store.s_store_name, ' - ', store.s_city) AS store_location,
    filtered_items.i_category,
    filtered_items.i_brand,
    SUM(store_sales.ss_net_profit) AS total_net_profit,
    COUNT(DISTINCT filtered_items.i_item_sk) AS distinct_items_sold,
    AVG(store_sales.ss_quantity) AS avg_quantity_per_sale
FROM store_sales
JOIN filtered_items
  ON store_sales.ss_item_sk = filtered_items.i_item_sk
JOIN store
  ON store_sales.ss_store_sk = store.s_store_sk
JOIN customer
  ON store_sales.ss_customer_sk = customer.c_customer_sk
JOIN household_demographics
  ON store_sales.ss_hdemo_sk = household_demographics.hd_demo_sk
JOIN time_dim
  ON store_sales.ss_sold_time_sk = time_dim.t_time_sk
WHERE household_demographics.hd_vehicle_count > 0
  AND regexp_like(customer.c_email_address, '^[A-Za-z0-9._%+-]+@example\\.com$')
  AND substring(store.s_store_name, 1, 5) = 'Store'
  AND time_dim.t_hour BETWEEN 9 AND 17
GROUP BY
    CONCAT(store.s_store_name, ' - ', store.s_city),
    filtered_items.i_category,
    filtered_items.i_brand
ORDER BY total_net_profit DESC
LIMIT 100
