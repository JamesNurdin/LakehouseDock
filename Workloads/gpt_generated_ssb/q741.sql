WITH order_fact AS (
    SELECT
        lo_orderkey,
        lo_custkey,
        lo_partkey,
        lo_suppkey,
        lo_orderdate,
        lo_commitdate,
        lo_quantity,
        lo_extendedprice,
        lo_discount,
        lo_revenue,
        lo_supplycost
    FROM lineorder
),
order_date_dim AS (
    SELECT
        d_datekey,
        d_year
    FROM dim_date
    WHERE d_year BETWEEN '1995' AND '1997'
),
commit_date_dim AS (
    SELECT
        d_datekey,
        d_year AS commit_year
    FROM dim_date
    WHERE d_year >= '1995'
),
joined_fact AS (
    SELECT
        od.d_year AS order_year,
        cd.commit_year,
        c.c_region AS customer_region,
        s.s_region AS supplier_region,
        p.p_category,
        f.lo_quantity,
        f.lo_revenue,
        f.lo_supplycost,
        f.lo_discount,
        f.lo_orderkey AS order_key
    FROM order_fact f
    JOIN order_date_dim od ON f.lo_orderdate = CAST(od.d_datekey AS INTEGER)
    JOIN commit_date_dim cd ON f.lo_commitdate = CAST(cd.d_datekey AS INTEGER)
    JOIN customer c ON f.lo_custkey = c.c_custkey
    JOIN part p ON f.lo_partkey = p.p_partkey
    JOIN supplier s ON f.lo_suppkey = s.s_suppkey
    WHERE p.p_category = 'MFGR#12'
      AND c.c_mktsegment = 'AUTOMOBILE'
)
SELECT
    order_year,
    customer_region,
    supplier_region,
    p_category,
    SUM(lo_quantity) AS total_quantity,
    SUM(lo_revenue) AS total_revenue,
    SUM(lo_revenue - lo_supplycost) AS total_profit,
    AVG(lo_discount) AS avg_discount,
    COUNT(DISTINCT order_key) AS distinct_orders
FROM joined_fact
GROUP BY order_year, customer_region, supplier_region, p_category
ORDER BY order_year, total_revenue DESC
