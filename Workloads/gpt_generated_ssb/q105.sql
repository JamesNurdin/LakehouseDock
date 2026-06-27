WITH order_info AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d_ord.d_year AS order_year,
        d_ord.d_date AS order_date,
        d_com.d_year AS commit_year,
        d_com.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_ord
        ON CAST(lo.lo_orderdate AS VARCHAR) = d_ord.d_datekey
    JOIN dim_date d_com
        ON CAST(lo.lo_commitdate AS VARCHAR) = d_com.d_datekey
    WHERE d_ord.d_date BETWEEN '1995-01-01' AND '1995-12-31'
),
agg AS (
    SELECT
        oi.order_year,
        c.c_region AS c_region,
        p.p_category AS p_category,
        SUM(oi.lo_revenue) AS total_revenue,
        SUM(oi.lo_supplycost) AS total_supply_cost,
        SUM(oi.lo_revenue - oi.lo_supplycost) AS total_profit,
        SUM(oi.lo_quantity) AS total_quantity
    FROM order_info oi
    JOIN customer c ON oi.lo_custkey = c.c_custkey
    JOIN part p ON oi.lo_partkey = p.p_partkey
    JOIN supplier s ON oi.lo_suppkey = s.s_suppkey
    GROUP BY oi.order_year, c.c_region, p.p_category
)
SELECT
    agg.order_year,
    agg.c_region,
    agg.p_category,
    agg.total_revenue,
    agg.total_supply_cost,
    agg.total_profit,
    agg.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY agg.order_year, agg.c_region ORDER BY agg.total_profit DESC) AS profit_rank
FROM agg
ORDER BY agg.total_profit DESC
LIMIT 10
