WITH per_month AS (
    SELECT
        cp.cp_catalog_page_id AS cp_id,
        d.d_month_seq AS month_seq,
        sm.sm_type AS ship_type,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(sr.sr_return_amt) AS returns_amount,
        SUM(cs.cs_quantity) AS catalog_qty,
        SUM(ws.ws_quantity) AS web_qty,
        SUM(sr.sr_return_quantity) AS return_qty
    FROM catalog_page cp
    JOIN catalog_sales cs
        ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND cp.cp_catalog_page_number BETWEEN 5 AND 20
    GROUP BY cp.cp_catalog_page_id, d.d_month_seq, sm.sm_type
),
page_avg AS (
    SELECT
        cp_id,
        AVG(catalog_sales_amount + web_sales_amount - returns_amount) AS avg_net_sales
    FROM per_month
    GROUP BY cp_id
)
SELECT
    pm.cp_id,
    pm.month_seq,
    pm.ship_type,
    (pm.catalog_sales_amount + pm.web_sales_amount - pm.returns_amount) AS net_sales,
    (pm.catalog_qty + pm.web_qty - pm.return_qty) AS net_qty,
    SUM(pm.catalog_sales_amount + pm.web_sales_amount - pm.returns_amount) OVER (
        PARTITION BY pm.cp_id
        ORDER BY pm.month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_net_sales,
    pa.avg_net_sales
FROM per_month pm
JOIN page_avg pa
    ON pm.cp_id = pa.cp_id
WHERE (pm.catalog_sales_amount + pm.web_sales_amount - pm.returns_amount) > pa.avg_net_sales
ORDER BY net_sales DESC
LIMIT 100
