WITH order_data AS (
    SELECT
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year,
        c.c_region,
        p.p_category,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_shipmode
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN dim_date d_commit
        ON CAST(d_commit.d_datekey AS INTEGER) = lo.lo_commitdate
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
)
SELECT
    order_year,
    commit_year,
    c_region,
    p_category,
    sum(lo_revenue) AS total_revenue,
    sum(lo_revenue - lo_supplycost) AS total_profit,
    avg(lo_discount) AS avg_discount
FROM order_data
WHERE order_year = '1995'
  AND commit_year = '1995'
  AND c_region = 'AMERICA'
  AND lo_shipmode = 'AIR'
GROUP BY order_year, commit_year, c_region, p_category
ORDER BY total_profit DESC
LIMIT 10
