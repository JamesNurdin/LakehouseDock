WITH date_dim AS (
    SELECT
        CAST(d_datekey AS INTEGER) AS d_date_key,
        d_date,
        d_year
    FROM dim_date
)
SELECT
    c.c_region,
    p.p_category,
    s.s_nation,
    date_dim.d_year,
    SUM(lo.lo_extendedprice) AS total_extended_price,
    SUM(lo.lo_revenue) AS total_revenue,
    SUM(lo.lo_supplycost) AS total_supply_cost,
    SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit
FROM lineorder lo
JOIN date_dim ON lo.lo_orderdate = date_dim.d_date_key
JOIN customer c ON lo.lo_custkey = c.c_custkey
JOIN part p ON lo.lo_partkey = p.p_partkey
JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
WHERE date_dim.d_date BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY c.c_region, p.p_category, s.s_nation, date_dim.d_year
ORDER BY total_profit DESC
LIMIT 10
