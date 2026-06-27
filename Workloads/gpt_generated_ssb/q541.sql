WITH revenue_by_year_region AS (
    SELECT
        d_order.d_year AS d_year,
        supplier.s_region AS s_region,
        sum(lineorder.lo_revenue) AS total_revenue,
        sum(lineorder.lo_revenue - lineorder.lo_supplycost * lineorder.lo_quantity) AS total_profit
    FROM lineorder
    JOIN dim_date AS d_order
        ON lineorder.lo_orderdate = cast(d_order.d_datekey AS integer)
    JOIN dim_date AS d_commit
        ON lineorder.lo_commitdate = cast(d_commit.d_datekey AS integer)
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    WHERE cast(d_order.d_date AS date) >= DATE '1995-01-01'
      AND cast(d_order.d_date AS date) <= DATE '1995-12-31'
      AND part.p_category = 'MFGR#12'
      AND supplier.s_region = 'ASIA'
      AND customer.c_region = 'AMERICA'
    GROUP BY d_order.d_year, supplier.s_region
)
SELECT
    d_year,
    s_region,
    total_revenue,
    total_profit,
    total_profit / total_revenue AS profit_margin
FROM revenue_by_year_region
ORDER BY d_year, s_region
