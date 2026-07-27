WITH base AS (
    SELECT
        d.d_year,
        cp.cp_department,
        ss.ss_net_paid,
        cs.cs_net_paid,
        ws.ws_net_paid,
        c.c_customer_sk,
        i.inv_quantity_on_hand,
        t.t_hour,
        ca.ca_state,
        cs.cs_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND t.t_hour BETWEEN 9 AND 17
      AND ca.ca_state = 'CA'
      AND cp.cp_department = 'Electronics'
      AND cs.cs_quantity > 2
      AND EXISTS (
          SELECT 1
          FROM inventory i2
          WHERE i2.inv_date_sk = d.d_date_sk
            AND i2.inv_quantity_on_hand > 500
      )
)
SELECT
    b.d_year,
    b.cp_department,
    SUM(b.ss_net_paid) AS store_sales_total,
    SUM(b.cs_net_paid) AS catalog_sales_total,
    SUM(b.ws_net_paid) AS web_sales_total,
    COUNT(DISTINCT b.c_customer_sk) AS unique_customers,
    AVG(b.inv_quantity_on_hand) AS avg_inventory_qty
FROM base b
GROUP BY b.d_year, b.cp_department
HAVING (SUM(b.ss_net_paid) + SUM(b.cs_net_paid) + SUM(b.ws_net_paid)) > 50000
ORDER BY store_sales_total DESC
LIMIT 100
