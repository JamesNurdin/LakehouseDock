WITH inv_site_agg AS (
    SELECT
        i.inv_warehouse_sk,
        ws.web_mkt_class,
        SUM(i.inv_quantity_on_hand) AS total_qty,
        COUNT(DISTINCT i.inv_date_sk) AS days_count
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    JOIN web_site ws ON ws.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.inv_quantity_on_hand > 0
      AND ws.web_country = 'United States'
      AND ws.web_gmt_offset > -5.00
    GROUP BY i.inv_warehouse_sk, ws.web_mkt_class
)
SELECT
    inv_warehouse_sk,
    AVG(total_qty) AS avg_total_qty,
    SUM(days_count) AS total_days
FROM inv_site_agg
GROUP BY inv_warehouse_sk
HAVING AVG(total_qty) > 5000
ORDER BY avg_total_qty DESC
LIMIT 100
