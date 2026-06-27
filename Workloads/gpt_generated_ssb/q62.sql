WITH filtered_orders AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        d.d_year,
        d.d_date,
        p.p_category,
        s.s_region
    FROM lineorder lo
    JOIN dim_date d
        ON cast(lo.lo_orderdate AS varchar) = d.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE cast(d.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
),
aggregated AS (
    SELECT
        d_year,
        p_category,
        s_region,
        sum(lo_revenue) AS total_revenue,
        sum(lo_revenue - lo_supplycost) AS total_profit,
        avg(lo_discount) AS avg_discount,
        sum(lo_quantity) AS total_quantity,
        count(DISTINCT lo_orderkey) AS order_cnt
    FROM filtered_orders
    GROUP BY d_year, p_category, s_region
)
SELECT
    d_year,
    p_category,
    s_region,
    total_revenue,
    total_profit,
    avg_discount,
    total_quantity,
    order_cnt,
    row_number() OVER (PARTITION BY d_year ORDER BY total_revenue DESC) AS revenue_rank
FROM aggregated
ORDER BY d_year, revenue_rank
