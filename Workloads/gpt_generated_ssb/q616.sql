WITH order_fact AS (
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
        d.d_year AS order_year,
        d.d_month AS order_month
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = CAST(d.d_datekey AS integer)
)
SELECT
    s.s_region,
    p.p_brand1,
    of.order_year,
    of.order_month,
    SUM(of.lo_revenue) AS total_revenue,
    SUM(of.lo_revenue - of.lo_supplycost - of.lo_tax) AS total_profit,
    AVG(of.lo_discount) AS avg_discount,
    COUNT(DISTINCT of.lo_orderkey) AS num_orders
FROM order_fact of
JOIN supplier s
    ON of.lo_suppkey = s.s_suppkey
JOIN part p
    ON of.lo_partkey = p.p_partkey
GROUP BY
    s.s_region,
    p.p_brand1,
    of.order_year,
    of.order_month
HAVING SUM(of.lo_revenue) > 1000000
ORDER BY total_profit DESC
LIMIT 50
