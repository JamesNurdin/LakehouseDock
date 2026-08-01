WITH
full_catalog AS (
    SELECT
        w.w_state AS state,
        d.d_year AS year,
        cs.cs_net_paid AS sales_amount
    FROM catalog_sales cs
    FULL OUTER JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000 OR d.d_year IS NULL
),
full_web AS (
    SELECT
        w.w_state AS state,
        d.d_year AS year,
        ws.ws_net_paid AS sales_amount
    FROM web_sales ws
    FULL OUTER JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000 OR d.d_year IS NULL
),
union_sales AS (
    SELECT state, year, sales_amount FROM full_catalog
    UNION
    SELECT state, year, sales_amount FROM full_web
),
aggregated AS (
    SELECT
        state,
        year,
        SUM(sales_amount) AS total_sales
    FROM union_sales
    GROUP BY CUBE (state, year)
)
SELECT
    state,
    year,
    total_sales,
    ROW_NUMBER() OVER (PARTITION BY state ORDER BY total_sales DESC) AS sales_rank
FROM aggregated
ORDER BY total_sales DESC
LIMIT 100
