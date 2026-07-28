WITH catalog_warehouse AS (
    SELECT
        warehouse.w_warehouse_name AS category,
        date_dim.d_year AS year,
        SUM(catalog_returns.cr_return_amount) AS total_return_amount
    FROM catalog_returns
    JOIN date_dim
        ON catalog_returns.cr_returned_date_sk = date_dim.d_date_sk
    JOIN warehouse
        ON catalog_returns.cr_warehouse_sk = warehouse.w_warehouse_sk
    WHERE regexp_like(warehouse.w_warehouse_name, '^WH[0-9]+')
      AND date_dim.d_year = 2001
    GROUP BY warehouse.w_warehouse_name, date_dim.d_year
    HAVING SUM(catalog_returns.cr_return_amount) > 1000
),
store_site AS (
    SELECT
        CONCAT(regexp_extract(ws.web_name, '([A-Za-z]+)'), '-', CAST(date_dim.d_year AS VARCHAR)) AS category,
        date_dim.d_year AS year,
        SUM(store_returns.sr_return_amt) AS total_return_amount
    FROM store_returns
    JOIN date_dim
        ON store_returns.sr_returned_date_sk = date_dim.d_date_sk
    JOIN time_dim
        ON store_returns.sr_return_time_sk = time_dim.t_time_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = date_dim.d_date_sk
    WHERE time_dim.t_meal_time LIKE 'Lunch%'
      AND ws.web_street_number LIKE '2%'
    GROUP BY CONCAT(regexp_extract(ws.web_name, '([A-Za-z]+)'), '-', CAST(date_dim.d_year AS VARCHAR)), date_dim.d_year
    HAVING SUM(store_returns.sr_return_amt) > 500
)
SELECT category, year, total_return_amount
FROM catalog_warehouse
UNION ALL
SELECT category, year, total_return_amount
FROM store_site
ORDER BY total_return_amount DESC
LIMIT 50
