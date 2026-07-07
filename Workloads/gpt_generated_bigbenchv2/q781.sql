SELECT
    c.c_customer_id,
    c.c_name,
    SUM(s.ss_quantity) AS total_quantity
FROM
    store_sales s
JOIN
    customers c
    ON s.ss_customer_id = c.c_customer_id
GROUP BY
    c.c_customer_id,
    c.c_name
ORDER BY
    total_quantity DESC
LIMIT 10
