WITH order_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        od.d_year,
        od.d_date,
        c.c_region,
        p.p_category,
        s.s_region AS supplier_region
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE od.d_year BETWEEN '1995' AND '1997'
),
agg AS (
    SELECT
        d_year,
        c_region,
        p_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supply_cost,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders
    FROM order_data
    GROUP BY d_year, c_region, p_category
)
SELECT
    d_year AS order_year,
    c_region,
    p_category,
    total_revenue,
    total_supply_cost,
    total_revenue - total_supply_cost AS profit,
    avg_discount,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_revenue - total_supply_cost DESC) AS profit_rank
FROM agg
ORDER BY d_year, profit_rank
