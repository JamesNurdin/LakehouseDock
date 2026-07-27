WITH sales_agg AS (
    SELECT
        ca.ca_state,
        ca.ca_location_type,
        SUM(cs.cs_net_paid) AS total_cs_net_paid,
        SUM(ss.ss_ext_sales_price) AS total_ss_ext_sales_price,
        COUNT(DISTINCT cs.cs_order_number) AS cs_orders,
        COUNT(DISTINCT ss.ss_ticket_number) AS ss_tickets
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN store_sales ss
        ON ss.ss_addr_sk = ca.ca_address_sk
    WHERE cs.cs_net_paid > 500
      AND cs.cs_ship_addr_sk IN (759318, 3619402, 743812)
      AND ca.ca_state = 'CA'
    GROUP BY ca.ca_state, ca.ca_location_type
)
SELECT
    ca_state,
    ca_location_type,
    total_cs_net_paid,
    COALESCE(total_ss_ext_sales_price, 0) AS total_ss_ext_sales_price,
    total_cs_net_paid / NULLIF(COALESCE(total_ss_ext_sales_price, 0), 0) AS cs_to_ss_ratio,
    ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_cs_net_paid DESC) AS rn,
    (SELECT AVG(total_cs_net_paid) FROM sales_agg) AS avg_total_cs_net_paid
FROM sales_agg
WHERE total_cs_net_paid > (SELECT AVG(total_cs_net_paid) FROM sales_agg)
ORDER BY total_cs_net_paid DESC
LIMIT 100
