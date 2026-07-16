WITH cs AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        w.w_warehouse_name AS warehouse,
        cp.cp_department AS department,
        t.t_hour AS hour_of_day,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(cs.cs_ext_discount_amt) AS catalog_discount,
        COUNT(*) AS catalog_txn
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cp.cp_type = 'monthly'
      AND d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq, w.w_warehouse_name, cp.cp_department, t.t_hour
),
ws AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        w.w_warehouse_name AS warehouse,
        'WEB' AS department,
        t.t_hour AS hour_of_day,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ws.ws_ext_discount_amt) AS web_discount,
        COUNT(*) AS web_txn
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2002
    GROUP BY d.d_year, d.d_month_seq, w.w_warehouse_name, t.t_hour
)
SELECT
    COALESCE(cs.year, ws.year) AS year,
    COALESCE(cs.month_seq, ws.month_seq) AS month_seq,
    COALESCE(cs.warehouse, ws.warehouse) AS warehouse,
    COALESCE(cs.department, ws.department) AS department,
    COALESCE(cs.hour_of_day, ws.hour_of_day) AS hour_of_day,
    cs.catalog_net_profit,
    ws.web_net_profit,
    (COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)) AS total_net_profit,
    (COALESCE(cs.catalog_sales, 0) + COALESCE(ws.web_sales, 0)) AS total_sales,
    CASE 
        WHEN (COALESCE(cs.catalog_sales, 0) + COALESCE(ws.web_sales, 0)) = 0 THEN 0
        ELSE (COALESCE(cs.catalog_discount, 0) + COALESCE(ws.web_discount, 0)) / (COALESCE(cs.catalog_sales, 0) + COALESCE(ws.web_sales, 0))
    END AS discount_rate,
    ROW_NUMBER() OVER (ORDER BY (COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)) DESC) AS profit_rank
FROM cs
FULL OUTER JOIN ws
    ON cs.year = ws.year
   AND cs.month_seq = ws.month_seq
   AND cs.warehouse = ws.warehouse
   AND cs.hour_of_day = ws.hour_of_day
WHERE (COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)) > 0
ORDER BY total_net_profit DESC
LIMIT 100
