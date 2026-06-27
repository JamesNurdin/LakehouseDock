WITH order_dim AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_supplycost,
        lo.lo_quantity,
        CAST(dd.d_datekey AS INTEGER) AS order_date_key,
        dd.d_year,
        dd.d_date
    FROM lineorder lo
    JOIN dim_date dd
        ON CAST(dd.d_datekey AS INTEGER) = lo.lo_orderdate
    WHERE dd.d_year = '1997'
),
customer_dim AS (
    SELECT
        c_custkey,
        c_region
    FROM customer
),
part_dim AS (
    SELECT
        p_partkey,
        p_category
    FROM part
),
supplier_dim AS (
    SELECT
        s_suppkey,
        s_nation
    FROM supplier
)
SELECT
    cd.c_region,
    od.d_year,
    pd.p_category,
    sd.s_nation,
    SUM(od.lo_extendedprice * (1 - od.lo_discount / 100.0)) AS revenue,
    SUM(od.lo_extendedprice * (1 - od.lo_discount / 100.0) - od.lo_supplycost) AS profit,
    AVG(od.lo_discount) AS avg_discount,
    COUNT(DISTINCT od.lo_orderkey) AS order_cnt
FROM order_dim od
JOIN customer_dim cd
    ON od.lo_custkey = cd.c_custkey
JOIN part_dim pd
    ON od.lo_partkey = pd.p_partkey
JOIN supplier_dim sd
    ON od.lo_suppkey = sd.s_suppkey
GROUP BY cd.c_region, od.d_year, pd.p_category, sd.s_nation
ORDER BY revenue DESC
LIMIT 100
