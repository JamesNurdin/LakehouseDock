WITH lo_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        d_order.d_year AS order_year,
        d_order.d_month AS order_month,
        d_order.d_date AS order_date,
        d_commit.d_year AS commit_year,
        d_commit.d_month AS commit_month,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS integer)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS integer)
    WHERE CAST(d_order.d_date AS DATE) BETWEEN DATE '1992-01-01' AND DATE '1997-12-31'
)
SELECT
    s.s_region,
    lo_dates.order_year,
    p.p_category,
    SUM(lo_dates.lo_revenue) AS total_revenue,
    SUM(lo_dates.lo_revenue - lo_dates.lo_supplycost) AS total_profit,
    AVG(lo_dates.lo_discount) AS avg_discount,
    COUNT(DISTINCT lo_dates.lo_orderkey) AS distinct_orders
FROM lo_dates
JOIN part p
    ON lo_dates.lo_partkey = p.p_partkey
JOIN supplier s
    ON lo_dates.lo_suppkey = s.s_suppkey
JOIN customer c
    ON lo_dates.lo_custkey = c.c_custkey
WHERE p.p_category = 'MFGR#12'
    AND s.s_region = 'AMERICA'
    AND lo_dates.order_month = 'January'
GROUP BY s.s_region, lo_dates.order_year, p.p_category
ORDER BY total_revenue DESC
LIMIT 10
