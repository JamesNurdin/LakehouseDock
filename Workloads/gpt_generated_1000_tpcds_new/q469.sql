WITH
    sampled_sales AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10) -- sample 10% of rows
        WHERE cs_quantity > 1
          AND cs_net_paid_inc_ship_tax > 500
          AND cs_ext_wholesale_cost BETWEEN 100 AND 2000
          AND cs_ship_mode_sk = 3
          AND cs_promo_sk IS NOT NULL
          AND cs_item_sk = 12345
    ),
    agg_sales AS (
        SELECT cs_bill_addr_sk,
               SUM(cs_net_paid)      AS sum_net_paid,
               AVG(cs_net_paid)      AS avg_net_paid,
               COUNT(*)              AS cnt_sales,
               MIN(cs_net_paid)      AS min_net_paid,
               MAX(cs_net_paid)      AS max_net_paid
        FROM sampled_sales
        GROUP BY cs_bill_addr_sk
    ),
    high_value_orders AS (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_net_paid > 2000
    ),
    low_value_orders AS (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_net_paid < 500
    ),
    order_except AS (
        SELECT cs_order_number FROM high_value_orders
        EXCEPT
        SELECT cs_order_number FROM low_value_orders
    ),
    order_intersect AS (
        SELECT cs_order_number FROM catalog_sales WHERE cs_quantity > 5
        INTERSECT
        SELECT cs_order_number FROM catalog_sales WHERE cs_ext_discount_amt > 50
    ),
    filtered_sales AS (
        SELECT *
        FROM catalog_sales
        WHERE cs_bill_addr_sk IN (SELECT ca_address_sk FROM customer_address WHERE ca_state = 'NY')
          AND cs_order_number IN (SELECT cs_order_number FROM order_except)
          AND cs_order_number IN (SELECT cs_order_number FROM order_intersect)
    )
SELECT
    ca.ca_state,
    ca.ca_city,
    ca.ca_location_type,
    agg.sum_net_paid,
    agg.avg_net_paid,
    agg.cnt_sales,
    agg.min_net_paid,
    agg.max_net_paid,
    (
        SELECT SUM(cs2.cs_net_paid)
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_addr_sk = ca.ca_address_sk
    ) AS total_net_paid_all_sales,
    (
        SELECT COUNT(*)
        FROM filtered_sales fs
        WHERE fs.cs_bill_addr_sk = ca.ca_address_sk
    ) AS filtered_order_count
FROM agg_sales agg
JOIN customer_address ca
    ON agg.cs_bill_addr_sk = ca.ca_address_sk
WHERE ca.ca_location_type = 'condo'
  AND ca.ca_street_name IN ('Lincoln', 'Main Second')
  AND ca.ca_city = 'Spring'
ORDER BY agg.sum_net_paid DESC
LIMIT 20
