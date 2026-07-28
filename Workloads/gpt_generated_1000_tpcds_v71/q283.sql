WITH year_2000_dates AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_year = 2000
)
SELECT metric_type,
       entity_name,
       metric_value
FROM (
    -- Profit per web site for preferred customers in the year 2000
    SELECT 'Profit' AS metric_type,
           ws_site.web_name AS entity_name,
           SUM(ws.ws_net_profit) AS metric_value
    FROM web_sales ws
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    JOIN year_2000_dates yd ON ws.ws_sold_date_sk = yd.d_date_sk
    WHERE EXISTS (
        SELECT 1
        FROM customer c
        WHERE c.c_customer_sk = ws.ws_bill_customer_sk
          AND c.c_preferred_cust_flag = 'Y'
    )
    GROUP BY ws_site.web_name

    UNION ALL

    -- Inventory quantity on hand per warehouse for the same year
    SELECT 'Inventory' AS metric_type,
           CAST(inv.inv_warehouse_sk AS varchar) AS entity_name,
           SUM(inv.inv_quantity_on_hand) AS metric_value
    FROM inventory inv
    JOIN year_2000_dates yd ON inv.inv_date_sk = yd.d_date_sk
    GROUP BY inv.inv_warehouse_sk
) AS combined
ORDER BY metric_type,
         metric_value DESC
LIMIT 100
