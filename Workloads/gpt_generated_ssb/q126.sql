WITH base AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        c.c_region AS cust_region,
        d.d_year,
        d.d_date,
        p.p_category,
        p.p_brand1,
        s.s_region AS supp_region
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year BETWEEN '1992' AND '1997'
),
agg AS (
    SELECT
        d_year,
        cust_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount
    FROM base
    GROUP BY d_year, cust_region, p_category
)
SELECT
    d_year,
    cust_region,
    p_category,
    total_revenue,
    total_profit,
    avg_discount,
    ROW_NUMBER() OVER (PARTITION BY d_year, cust_region ORDER BY total_revenue DESC) AS revenue_rank_by_region_year
FROM agg
ORDER BY d_year, cust_region, revenue_rank_by_region_year
