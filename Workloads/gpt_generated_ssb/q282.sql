WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
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
        lo.lo_shipmode,
        CAST(lo.lo_orderdate AS VARCHAR) AS order_datekey,
        CAST(lo.lo_commitdate AS VARCHAR) AS commit_datekey,
        dim_order.d_year AS order_year,
        dim_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date AS dim_order
        ON CAST(lo.lo_orderdate AS VARCHAR) = dim_order.d_datekey
    JOIN dim_date AS dim_commit
        ON CAST(lo.lo_commitdate AS VARCHAR) = dim_commit.d_datekey
)
SELECT
    agg.order_year,
    agg.c_region,
    agg.p_category,
    agg.supplier_region,
    agg.total_revenue,
    agg.total_profit,
    agg.avg_discount,
    agg.order_count,
    RANK() OVER (PARTITION BY agg.c_region ORDER BY agg.total_revenue DESC) AS revenue_rank
FROM (
    SELECT
        od.order_year,
        c.c_region,
        p.p_category,
        s.s_region AS supplier_region,
        SUM(od.lo_revenue) AS total_revenue,
        SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
        AVG(od.lo_discount) AS avg_discount,
        COUNT(*) AS order_count
    FROM order_dates od
    JOIN customer c
        ON od.lo_custkey = c.c_custkey
    JOIN part p
        ON od.lo_partkey = p.p_partkey
    JOIN supplier s
        ON od.lo_suppkey = s.s_suppkey
    WHERE
        p.p_category = 'MFGR#1'
        AND c.c_region = 'ASIA'
        AND s.s_region = 'EUROPE'
        AND od.commit_year >= od.order_year
    GROUP BY
        od.order_year,
        c.c_region,
        p.p_category,
        s.s_region
) agg
ORDER BY agg.order_year, revenue_rank
