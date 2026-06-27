WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_commitdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_quantity,
        lo.lo_ordertotalprice,
        lo.lo_tax,
        lo.lo_shipmode,
        d_order.d_date AS order_date,
        d_order.d_year AS order_year,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN dim_date d_order
        ON lo.lo_orderdate = CAST(d_order.d_datekey AS integer)
    JOIN dim_date d_commit
        ON lo.lo_commitdate = CAST(d_commit.d_datekey AS integer)
)
SELECT
    s.s_region,
    p.p_brand1,
    SUM(o.lo_revenue) AS total_revenue,
    SUM(o.lo_supplycost) AS total_supply_cost,
    SUM(o.lo_revenue - o.lo_supplycost) AS total_profit,
    AVG(o.lo_discount) AS avg_discount,
    AVG(date_diff('day', CAST(o.order_date AS date), CAST(o.commit_date AS date))) AS avg_lead_time_days,
    COUNT(DISTINCT o.lo_orderkey) AS order_count
FROM order_dates o
JOIN customer c
    ON o.lo_custkey = c.c_custkey
JOIN part p
    ON o.lo_partkey = p.p_partkey
JOIN supplier s
    ON o.lo_suppkey = s.s_suppkey
WHERE
    o.order_year = '1997'
    AND p.p_category = 'MFGR#12'
    AND c.c_mktsegment = 'AUTOMOBILE'
    AND s.s_region IN ('ASIA', 'EUROPE')
GROUP BY
    s.s_region,
    p.p_brand1
ORDER BY
    total_profit DESC
LIMIT 100
