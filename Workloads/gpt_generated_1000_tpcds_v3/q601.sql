WITH page_state_sales AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_type,
        ca.ca_state,
        SUM(cs.cs_net_paid_inc_ship) AS total_net_paid,
        COUNT(*) AS order_cnt
    FROM
        catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    WHERE
        cp.cp_type IN ('monthly', 'quarterly')
        AND cp.cp_catalog_number >= 5
        AND cs.cs_net_paid_inc_ship > 1000
        AND EXISTS (
            SELECT 1
            FROM customer_address ca_ship
            WHERE ca_ship.ca_address_sk = cs.cs_ship_addr_sk
              AND ca_ship.ca_state = 'CA'
        )
    GROUP BY
        cp.cp_catalog_page_id,
        cp.cp_type,
        ca.ca_state
)
SELECT
    cp_type,
    AVG(total_net_paid) AS avg_total_net_paid,
    SUM(order_cnt) AS total_orders
FROM page_state_sales
WHERE total_net_paid > 5000
GROUP BY cp_type
ORDER BY avg_total_net_paid DESC
LIMIT 100
