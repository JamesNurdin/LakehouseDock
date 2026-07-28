WITH filtered_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_ship_date_sk,
        cs.cs_ext_wholesale_cost,
        cs.cs_ext_ship_cost,
        cs.cs_net_paid,
        cs.cs_net_profit,
        ca.ca_address_sk,
        ca.ca_state,
        ca.ca_city,
        ca.ca_zip,
        ca.ca_gmt_offset
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE cs.cs_ext_wholesale_cost > 2000
      AND cs.cs_ship_date_sk BETWEEN 2450845 AND 2450914
      AND ca.ca_gmt_offset = -5.00
      AND ca.ca_zip LIKE '9%'
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_order_number = cs.cs_order_number
            AND cs2.cs_ext_discount_amt > 500
      )
),
agg_sales AS (
    SELECT
        ca_state,
        ca_city,
        SUM(cs_net_paid) AS total_net_paid,
        AVG(cs_net_profit) AS avg_net_profit
    FROM filtered_sales
    GROUP BY ROLLUP (ca_state, ca_city)
    HAVING SUM(cs_net_paid) > 10000
)
SELECT
    ca_state,
    ca_city,
    total_net_paid,
    avg_net_profit,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_net_paid DESC) AS state_rank,
    (SELECT AVG(cs_net_profit) FROM filtered_sales) AS overall_avg_profit
FROM agg_sales
ORDER BY total_net_paid DESC
LIMIT 100
