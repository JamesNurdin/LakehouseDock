WITH inv_summary AS (
    SELECT
        w.w_warehouse_id AS entity_id,
        d.d_date AS activity_date,
        CAST('inventory' AS VARCHAR) AS activity_type,
        SUM(i.inv_quantity_on_hand) AS metric
    FROM inventory i
    JOIN date_dim d
        ON i.inv_date_sk = d.d_date_sk
    JOIN warehouse w
        ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND i.inv_quantity_on_hand > 200
    GROUP BY w.w_warehouse_id, d.d_date
),
web_page_summary AS (
    SELECT
        c.c_customer_id AS entity_id,
        d.d_date AS activity_date,
        CAST('web_page' AS VARCHAR) AS activity_type,
        COUNT(*) AS metric
    FROM web_page wp
    JOIN date_dim d
        ON wp.wp_access_date_sk = d.d_date_sk
    JOIN customer c
        ON wp.wp_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2001
      AND wp.wp_type = 'Home'
    GROUP BY c.c_customer_id, d.d_date
)
SELECT entity_id, activity_date, activity_type, metric
FROM inv_summary
UNION ALL
SELECT entity_id, activity_date, activity_type, metric
FROM web_page_summary
ORDER BY activity_date DESC, metric DESC
LIMIT 100
