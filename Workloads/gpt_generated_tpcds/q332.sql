WITH customers_on_date AS (
    SELECT COUNT(DISTINCT c.c_customer_sk) AS total_customers
    FROM customer c
    JOIN date_dim d_cust ON c.c_first_sales_date_sk = d_cust.d_date_sk
    WHERE d_cust.d_date = DATE '2022-12-31'
),
websites_on_date AS (
    SELECT AVG(ws.web_tax_percentage) AS avg_tax
    FROM web_site ws
    JOIN date_dim d_ws ON ws.web_open_date_sk = d_ws.d_date_sk
    WHERE d_ws.d_date = DATE '2022-12-31'
)
SELECT
    w.w_warehouse_name,
    i.i_category,
    SUM(inv.inv_quantity_on_hand) AS total_quantity_on_hand,
    AVG(i.i_current_price) AS avg_item_price,
    cust.total_customers,
    ws.avg_tax
FROM inventory inv
JOIN date_dim d_inv ON inv.inv_date_sk = d_inv.d_date_sk
JOIN item i ON inv.inv_item_sk = i.i_item_sk
JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
CROSS JOIN customers_on_date cust
CROSS JOIN websites_on_date ws
WHERE d_inv.d_date = DATE '2022-12-31'
GROUP BY w.w_warehouse_name, i.i_category, cust.total_customers, ws.avg_tax
ORDER BY total_quantity_on_hand DESC
LIMIT 10
