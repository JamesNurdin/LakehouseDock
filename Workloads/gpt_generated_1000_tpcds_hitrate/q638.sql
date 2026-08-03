WITH agg_inventory AS (
    SELECT
        inv_warehouse_sk,
        inv_date_sk,
        SUM(inv_quantity_on_hand) AS total_qty
    FROM inventory
    GROUP BY inv_warehouse_sk, inv_date_sk
),
warehouse_map AS (
    SELECT
        w_warehouse_sk,
        w_warehouse_name,
        w_city,
        w_state,
        w_county,
        MAP(ARRAY['city','state'], ARRAY[w_city, w_state]) AS loc_map
    FROM warehouse
)
SELECT
    d.d_year,
    w.w_warehouse_name,
    s.s_store_name,
    ws.web_name,
    COUNT(DISTINCT c.c_customer_sk) AS num_customers,
    SUM(ai.total_qty) AS total_inventory,
    MIN(d.d_date) AS earliest_date,
    MAX(d.d_date) AS latest_date
FROM agg_inventory ai
JOIN warehouse_map w ON ai.inv_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d ON ai.inv_date_sk = d.d_date_sk
FULL OUTER JOIN store s ON s.s_closed_date_sk = d.d_date_sk
LEFT JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
LEFT JOIN customer c ON c.c_first_sales_date_sk = d.d_date_sk
LEFT JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    AND wp.wp_creation_date_sk = d.d_date_sk
CROSS JOIN UNNEST(w.loc_map) AS t(loc_key, loc_value)
WHERE w.w_county IN ('Richland County', 'Walker County')
  AND d.d_fy_year = 1907
  AND ws.web_class = 'News'
  AND loc_key = 'state' AND loc_value = 'CA'
  AND c.c_customer_sk IN (
        SELECT wp_customer_sk FROM web_page WHERE wp_type = 'home'
    )
  AND EXISTS (
        SELECT 1 FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_type = 'product'
    )
GROUP BY d.d_year, w.w_warehouse_name, s.s_store_name, ws.web_name
ORDER BY total_inventory DESC
LIMIT 100
