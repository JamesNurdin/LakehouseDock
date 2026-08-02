WITH catalog_sales_agg AS (
    SELECT
        d.d_year AS year,
        w.w_warehouse_name AS warehouse_name,
        SUM(cs.cs_net_paid_inc_tax) AS total_amount,
        'catalog_sales' AS source
    FROM (
        SELECT *
        FROM tpcds.catalog_sales
        TABLESAMPLE BERNOULLI (10)
    ) AS cs
    INNER JOIN tpcds.date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    INNER JOIN tpcds.time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    INNER JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2002
      AND t.t_hour BETWEEN 12 AND 23
    GROUP BY d.d_year, w.w_warehouse_name
),
store_returns_agg AS (
    SELECT
        d.d_year AS year,
        'Store' AS warehouse_name,
        SUM(sr.sr_net_loss) AS total_amount,
        'store_returns' AS source
    FROM (
        SELECT *
        FROM tpcds.store_returns
        TABLESAMPLE BERNOULLI (5)
    ) AS sr
    INNER JOIN tpcds.date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN tpcds.time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    INNER JOIN tpcds.customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE d.d_year = 2002
      AND t.t_am_pm = 'PM'
    GROUP BY d.d_year
)
SELECT year, warehouse_name, total_amount, source
FROM catalog_sales_agg
UNION ALL
SELECT year, warehouse_name, total_amount, source
FROM store_returns_agg
ORDER BY year, source
