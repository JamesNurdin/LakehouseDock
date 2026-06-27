/*
  Revenue, profit and month‑over‑month growth by customer region, year, month and product category.
  Uses only the allowed tables and join rules, with explicit column qualification.
*/
WITH base AS (
    SELECT
        c.c_region               AS cust_region,
        d.d_year,
        d.d_monthnuminyear,
        p.p_category,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey               -- lineorder.lo_orderdate = dim_date.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey                                 -- lineorder.lo_custkey = customer.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey                                 -- lineorder.lo_partkey = part.p_partkey
    WHERE d.d_year BETWEEN '1995' AND '1997'                           -- filter on the date dimension
),
agg AS (
    SELECT
        cust_region,
        d_year,
        d_monthnuminyear,
        p_category,
        SUM(lo_revenue)      AS total_revenue,
        SUM(lo_supplycost)   AS total_supply_cost,
        SUM(lo_quantity)     AS total_quantity,
        AVG(lo_discount)     AS avg_discount
    FROM base
    GROUP BY cust_region, d_year, d_monthnuminyear, p_category
)
SELECT
    cust_region,
    d_year,
    d_monthnuminyear,
    p_category,
    total_revenue,
    total_supply_cost,
    total_revenue - total_supply_cost AS profit,
    total_quantity,
    avg_discount,
    LAG(total_revenue) OVER (
        PARTITION BY cust_region, p_category
        ORDER BY d_year, d_monthnuminyear
    ) AS prev_month_revenue,
    CASE
        WHEN LAG(total_revenue) OVER (
            PARTITION BY cust_region, p_category
            ORDER BY d_year, d_monthnuminyear
        ) IS NULL THEN NULL
        ELSE (
            total_revenue - LAG(total_revenue) OVER (
                PARTITION BY cust_region, p_category
                ORDER BY d_year, d_monthnuminyear
            )
        ) / LAG(total_revenue) OVER (
            PARTITION BY cust_region, p_category
            ORDER BY d_year, d_monthnuminyear
        ) * 100
    END AS revenue_growth_pct
FROM agg
ORDER BY cust_region, d_year, d_monthnuminyear, p_category
