WITH sales_agg AS (
    SELECT
        ca.ca_state,
        c.c_birth_month,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE EXISTS (
            SELECT 1
            FROM customer_address ca2
            WHERE ca2.ca_address_sk = cs.cs_ship_addr_sk
              AND ca2.ca_state = 'CA'
        )
      AND cs.cs_ext_wholesale_cost > 2000
      AND cs.cs_list_price BETWEEN 50 AND 150
      AND c.c_birth_year = 1975
    GROUP BY ROLLUP (ca.ca_state, c.c_birth_month)
)
SELECT
    ca_state,
    c_birth_month,
    total_net_paid,
    order_cnt,
    RANK() OVER (PARTITION BY ca_state ORDER BY total_net_paid DESC) AS state_rank,
    ROW_NUMBER() OVER (ORDER BY total_net_paid DESC) AS overall_row_num
FROM sales_agg
ORDER BY ca_state, c_birth_month
LIMIT 100
