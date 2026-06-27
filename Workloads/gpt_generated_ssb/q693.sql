WITH order_dates AS (
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
        lo.lo_shipmode,
        d_order.d_year AS order_year,
        d_order.d_date AS order_date,
        d_commit.d_date AS commit_date,
        p.p_category AS part_category
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS integer)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS integer)
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
)
SELECT
    od.order_year,
    od.part_category,
    c.c_mktsegment,
    s.s_region,
    SUM(od.lo_revenue) AS total_revenue,
    SUM(od.lo_revenue - od.lo_supplycost) AS total_profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS distinct_orders,
    COUNT(*) AS lineitem_count,
    AVG(date_diff('day',
        DATE_PARSE(od.order_date, '%Y-%m-%d'),
        DATE_PARSE(od.commit_date, '%Y-%m-%d')
    )) AS avg_days_to_commit
FROM order_dates od
JOIN customer c
    ON od.lo_custkey = c.c_custkey
JOIN supplier s
    ON od.lo_suppkey = s.s_suppkey
WHERE od.order_year = '1995'
GROUP BY od.order_year, od.part_category, c.c_mktsegment, s.s_region
ORDER BY od.order_year, total_revenue DESC
LIMIT 100
