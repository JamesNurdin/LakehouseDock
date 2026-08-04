WITH sales_agg AS (
    SELECT
        d.d_year,
        p.p_promo_name,
        SUM(cs.cs_net_paid) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    GROUP BY GROUPING SETS (
        (d.d_year),
        (d.d_year, p.p_promo_name)
    )
),
sales_agg_time AS (
    SELECT
        d.d_year,
        CAST(NULL AS varchar) AS p_promo_name,
        SUM(cs.cs_net_paid) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
    GROUP BY d.d_year
),
sales_warehouse_excl AS (
    SELECT
        d.d_year,
        p.p_promo_name,
        SUM(cs.cs_net_paid) AS total_sales
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
    GROUP BY d.d_year, p.p_promo_name
)
(
    SELECT d_year, p_promo_name, total_sales FROM sales_agg
    INTERSECT
    SELECT d_year, p_promo_name, total_sales FROM sales_agg_time
)
EXCEPT
SELECT d_year, p_promo_name, total_sales FROM sales_warehouse_excl
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
