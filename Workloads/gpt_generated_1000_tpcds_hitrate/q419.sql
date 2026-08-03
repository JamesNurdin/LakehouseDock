WITH sales_cte AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_bill_addr_sk,
        cs.cs_item_sk,
        cs.cs_order_number,
        cs.cs_net_paid_inc_tax,
        cs.cs_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT
    ca.ca_address_id,
    ca.ca_suite_number,
    regexp_extract(ca.ca_suite_number, '\\d+', 0) AS suite_num,
    CASE
        WHEN try_cast(regexp_extract(ca.ca_suite_number, '\\d+', 0) AS integer) > 50 THEN 'High'
        ELSE 'Low'
    END AS suite_category,
    SUM(s.cs_net_paid_inc_tax) AS total_net_paid,
    COUNT(DISTINCT s.cs_item_sk) AS distinct_items,
    COUNT(*) AS orders_count
FROM sales_cte s
JOIN customer_address ca ON s.cs_bill_addr_sk = ca.ca_address_sk
JOIN web_site w ON w.web_open_date_sk = s.cs_sold_date_sk
WHERE regexp_like(ca.ca_suite_number, '^Suite [0-9]+')
  AND ca.ca_address_id LIKE 'AAAAAAA%'
  AND s.cs_item_sk IN (
        SELECT i.inv_item_sk
        FROM inventory i
        WHERE i.inv_quantity_on_hand > 100
    )
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns r
        WHERE r.cr_order_number = s.cs_order_number
    )
GROUP BY
    ca.ca_address_id,
    ca.ca_suite_number,
    regexp_extract(ca.ca_suite_number, '\\d+', 0),
    CASE
        WHEN try_cast(regexp_extract(ca.ca_suite_number, '\\d+', 0) AS integer) > 50 THEN 'High'
        ELSE 'Low'
    END
ORDER BY total_net_paid DESC
LIMIT 100
