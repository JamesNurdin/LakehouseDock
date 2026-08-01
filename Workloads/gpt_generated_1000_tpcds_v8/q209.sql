WITH full_inventory_date AS (
   SELECT
       d.d_year,
       inv.inv_warehouse_sk,
       inv.inv_quantity_on_hand,
       inv.inv_item_sk
   FROM inventory inv
   FULL OUTER JOIN date_dim d
       ON inv.inv_date_sk = d.d_date_sk
   WHERE d.d_year BETWEEN 2001 AND 2002 OR d.d_year IS NULL
),
recent_ws AS (
   SELECT
       ws.ws_sold_date_sk,
       ws.ws_item_sk,
       ws.ws_ext_sales_price,
       ws.ws_net_paid,
       ws.ws_web_site_sk,
       ws.ws_bill_addr_sk
   FROM web_sales ws
   JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
   WHERE d.d_year = 2002
)
SELECT
    result.year,
    result.metric_name,
    result.metric_value,
    result.distinct_cnt
FROM (
    SELECT
        d.d_year AS year,
        'Web Sales Net Paid' AS metric_name,
        SUM(DISTINCT ws.ws_net_paid) AS metric_value,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_cnt
    FROM recent_ws ws
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE w.web_state IN (
        SELECT web_state
        FROM web_site
        WHERE web_country = 'USA'
        LIMIT 1
    )
    GROUP BY d.d_year

    UNION ALL

    SELECT
        f.d_year AS year,
        'Inventory Qty' AS metric_name,
        SUM(DISTINCT f.inv_quantity_on_hand) AS metric_value,
        COUNT(DISTINCT f.inv_item_sk) AS distinct_cnt
    FROM full_inventory_date f
    GROUP BY f.d_year
) AS result
ORDER BY result.year DESC, result.metric_name
LIMIT 100
