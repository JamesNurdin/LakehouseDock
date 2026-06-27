WITH lo_joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_quantity,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        c.c_region,
        s.s_region,
        p.p_category,
        d_o.d_year,
        CAST(d_o.d_date AS date) AS order_date,
        CAST(d_c.d_date AS date) AS commit_date
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN dim_date d_o
        ON CAST(lo.lo_orderdate AS varchar) = d_o.d_datekey
    JOIN dim_date d_c
        ON CAST(lo.lo_commitdate AS varchar) = d_c.d_datekey
    WHERE d_o.d_year = '1997'
)

SELECT
    loj.d_year AS order_year,
    loj.c_region,
    loj.s_region,
    loj.p_category,
    SUM(loj.lo_revenue) AS total_revenue,
    SUM(loj.lo_supplycost) AS total_supply_cost,
    SUM(loj.lo_revenue) - SUM(loj.lo_supplycost) AS total_profit,
    AVG(date_diff('day', loj.order_date, loj.commit_date)) AS avg_lead_time_days,
    COUNT(DISTINCT loj.lo_orderkey) AS distinct_orders,
    AVG(loj.lo_discount) AS avg_discount
FROM lo_joined loj
GROUP BY
    loj.d_year,
    loj.c_region,
    loj.s_region,
    loj.p_category
ORDER BY total_profit DESC
LIMIT 100
