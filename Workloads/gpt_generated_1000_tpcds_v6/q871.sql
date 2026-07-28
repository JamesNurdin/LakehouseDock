WITH sales_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws.ws_sold_date_sk,
        cp.cp_department,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    LEFT JOIN catalog_page cp
        ON cp.cp_start_date_sk = d_sold.d_date_sk
    WHERE d_sold.d_year = 2001                                   -- predicate 1
      AND d_sold.d_month_seq BETWEEN 1200 AND 1210               -- predicate 2
      AND t.t_hour BETWEEN 8 AND 18                               -- predicate 3
      AND w.web_company_id IN (1, 3, 5)                           -- predicate 4
      AND cp.cp_department IN ('Electronics', 'Books', 'Clothing') -- predicate 5
      AND cp.cp_end_date_sk >= d_sold.d_date_sk                    -- predicate 6 (filter on catalog_page)
      AND ws.ws_quantity > 1                                      -- predicate 7
    GROUP BY ws.ws_web_site_sk, ws.ws_sold_date_sk, cp.cp_department
)
SELECT
    COALESCE(w.web_name, 'All Sites') AS website,
    COALESCE(sa.cp_department, 'All Departments') AS department,
    d.d_date,
    SUM(sa.total_sales) AS sum_sales,
    SUM(sa.total_profit) AS sum_profit,
    SUM(sa.order_cnt) AS total_orders,
    GROUPING(w.web_name) AS grp_site,
    GROUPING(sa.cp_department) AS grp_dept,
    GROUPING(d.d_date) AS grp_date
FROM sales_agg sa
JOIN date_dim d
    ON sa.ws_sold_date_sk = d.d_date_sk
JOIN web_site w
    ON sa.ws_web_site_sk = w.web_site_sk
GROUP BY GROUPING SETS (
    (w.web_name, sa.cp_department, d.d_date),
    (w.web_name, sa.cp_department),
    (w.web_name),
    ()
)
ORDER BY sum_sales DESC
LIMIT 100
