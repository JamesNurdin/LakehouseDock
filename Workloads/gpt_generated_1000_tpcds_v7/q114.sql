WITH sales_joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_net_paid_inc_tax,
        cs.cs_ship_date_sk,
        cs.cs_ext_tax,
        cs.cs_quantity,
        cs.cs_item_sk,
        i.i_product_name,
        i.i_wholesale_cost,
        i.i_size,
        ca.ca_city,
        ca.ca_state
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    WHERE cs.cs_ship_date_sk BETWEEN 2450860 AND 2450895
      AND cs.cs_ext_tax > 50
      AND i.i_wholesale_cost < 20
      AND ca.ca_city IN ('Woodland', 'Elm')
      AND cs.cs_quantity > 1
)
SELECT
    sj.cs_order_number,
    sj.cs_net_profit,
    sj.i_product_name,
    sj.ca_city,
    sj.ca_state,
    (
        SELECT AVG(cs2.cs_net_paid_inc_tax)
        FROM catalog_sales cs2
        WHERE cs2.cs_item_sk = sj.cs_item_sk
    ) AS avg_item_net_paid_inc_tax,
    rank() OVER (PARTITION BY sj.ca_state ORDER BY sj.cs_net_profit DESC) AS profit_state_rank
FROM sales_joined sj
WHERE EXISTS (
    SELECT 1
    FROM item i2
    WHERE i2.i_item_sk = sj.cs_item_sk
      AND i2.i_category = 'Electronics'
)
ORDER BY profit_state_rank, sj.cs_order_number
LIMIT 100
