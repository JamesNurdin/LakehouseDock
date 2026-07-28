WITH sales_by_city AS (
    SELECT
        ca.ca_city,
        ca.ca_state,
        SUM(cs.cs_net_paid) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM catalog_sales cs
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND ca.ca_city LIKE '%View%'
      AND regexp_like(i.i_item_desc, '\\d{3}')
    GROUP BY ca.ca_city, ca.ca_state
)
SELECT DISTINCT
    ca_city || ', ' || ca_state AS city_state,
    total_net_paid,
    CASE
        WHEN total_net_paid < 10000 THEN 'Low'
        WHEN total_net_paid < 50000 THEN 'Medium'
        ELSE 'High'
    END AS sales_bucket
FROM sales_by_city
ORDER BY total_net_paid DESC
LIMIT 10
