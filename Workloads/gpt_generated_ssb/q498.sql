/*
  Analytical query: Top‑3 part categories by revenue for each customer region and order year
  (1993‑01‑01 to 1995‑12‑31).  Uses only the selected SSB tables and the allowed join rules.
*/
WITH filtered_orders AS (
    -- Join lineorder to the date dimension for both order and commit dates
    SELECT
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        d_order.d_year,
        d_order.d_date,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
    WHERE d_order.d_date >= '1993-01-01'
      AND d_order.d_date <= '1995-12-31'
      AND d_commit.d_date >= '1993-01-01'
      AND d_commit.d_date <= '1995-12-31'
),
enriched AS (
    -- Add customer region and part category information
    SELECT
        fo.lo_custkey,
        fo.lo_partkey,
        fo.lo_revenue,
        fo.lo_supplycost,
        fo.d_year,
        c.c_region,
        p.p_category
    FROM filtered_orders fo
    JOIN customer c
        ON fo.lo_custkey = c.c_custkey
    JOIN part p
        ON fo.lo_partkey = p.p_partkey
),
agg AS (
    -- Aggregate revenue and profit per region / year / category
    SELECT
        c_region,
        d_year,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit
    FROM enriched
    GROUP BY c_region, d_year, p_category
),
ranked AS (
    -- Rank categories by revenue within each region‑year pair
    SELECT
        c_region,
        d_year,
        p_category,
        total_revenue,
        total_profit,
        ROW_NUMBER() OVER (PARTITION BY c_region, d_year ORDER BY total_revenue DESC) AS rn
    FROM agg
)
SELECT
    c_region,
    d_year,
    p_category,
    total_revenue,
    total_profit,
    (total_profit / NULLIF(total_revenue, 0)) AS profit_margin
FROM ranked
WHERE rn <= 3
ORDER BY c_region, d_year, rn
