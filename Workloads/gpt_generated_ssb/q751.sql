WITH order_details AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_tax,
        lo.lo_shipmode,
        lo.lo_orderpriority,
        lo.lo_shippriority,
        lo.lo_linenumber,
        (lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
),
region_year_profit AS (
    SELECT
        s.s_region,
        d_order.d_year,
        SUM(od.profit) AS total_profit,
        COUNT(*) AS order_line_count,
        AVG(od.profit) AS avg_profit_per_line
    FROM order_details od
    JOIN customer c
        ON od.lo_custkey = c.c_custkey
    JOIN part p
        ON od.lo_partkey = p.p_partkey
    JOIN supplier s
        ON od.lo_suppkey = s.s_suppkey
    JOIN dim_date d_order
        ON CAST(od.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit
        ON CAST(od.lo_commitdate AS varchar) = d_commit.d_datekey
    WHERE CAST(d_commit.d_date AS date) >= DATE '1995-01-01'
      AND CAST(d_commit.d_date AS date) < DATE '1996-01-01'
      AND p.p_mfgr = 'MFGR#1'
    GROUP BY s.s_region, d_order.d_year
)
SELECT
    ryp.s_region,
    ryp.d_year,
    ryp.total_profit,
    ryp.order_line_count,
    ryp.avg_profit_per_line,
    SUM(ryp.total_profit) OVER (PARTITION BY ryp.s_region ORDER BY ryp.d_year) AS cumulative_profit_by_region
FROM region_year_profit ryp
ORDER BY ryp.s_region, ryp.d_year
