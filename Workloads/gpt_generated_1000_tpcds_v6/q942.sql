WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        ws.ws_web_site_sk,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        CASE WHEN SUM(ws.ws_net_profit) > 1000 THEN 'High' ELSE 'Low' END AS profit_category
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_site s ON ws.ws_web_site_sk = s.web_site_sk
    WHERE d.d_year IN (2000, 2001)
    GROUP BY d.d_year, d.d_month_seq, ws.ws_web_site_sk
),
inventory_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.inv_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_quantity
    FROM inventory i
    JOIN date_dim d ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year IN (2000, 2001)
    GROUP BY d.d_year, d.d_month_seq, i.inv_warehouse_sk
)
SELECT
    CAST(sa.d_year AS varchar) || '-' || CAST(sa.d_month_seq AS varchar) AS period,
    'sales' AS metric,
    CAST(sa.total_sales AS decimal(15,2)) AS amount,
    sa.profit_category
FROM sales_agg sa
WHERE sa.d_year = 2000
UNION ALL
SELECT
    CAST(sa.d_year AS varchar) || '-' || CAST(sa.d_month_seq AS varchar) AS period,
    'sales' AS metric,
    CAST(sa.total_sales AS decimal(15,2)) AS amount,
    sa.profit_category
FROM sales_agg sa
WHERE sa.d_year = 2001
UNION ALL
SELECT
    CAST(ia.d_year AS varchar) || '-' || CAST(ia.d_month_seq AS varchar) AS period,
    'inventory' AS metric,
    CAST(ia.total_quantity AS decimal(15,2)) AS amount,
    CAST(NULL AS varchar) AS profit_category
FROM inventory_agg ia
WHERE ia.d_year = 2000
UNION ALL
SELECT
    CAST(ia.d_year AS varchar) || '-' || CAST(ia.d_month_seq AS varchar) AS period,
    'inventory' AS metric,
    CAST(ia.total_quantity AS decimal(15,2)) AS amount,
    CAST(NULL AS varchar) AS profit_category
FROM inventory_agg ia
WHERE ia.d_year = 2001
ORDER BY period, metric
LIMIT 100
