WITH order_dim AS (
    SELECT d_datekey, d_year, d_date
    FROM dim_date
),
commit_dim AS (
    SELECT d_datekey, d_year, d_date
    FROM dim_date
),
lineorder_enriched AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
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
        lo.lo_orderpriority,
        lo.lo_shippriority,
        od.d_year      AS order_year,
        od.d_date      AS order_date,
        cd.d_year      AS commit_year,
        cd.d_date      AS commit_date,
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        p.p_category,
        p.p_brand1,
        s.s_region    AS supplier_region,
        (lo.lo_revenue - lo.lo_supplycost) AS profit
    FROM lineorder lo
    JOIN customer c   ON lo.lo_custkey = c.c_custkey
    JOIN part p       ON lo.lo_partkey = p.p_partkey
    JOIN supplier s   ON lo.lo_suppkey = s.s_suppkey
    JOIN order_dim od ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN commit_dim cd ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
)
SELECT
    le.order_year,
    le.c_region,
    le.p_category,
    SUM(le.lo_revenue)          AS total_revenue,
    SUM(le.profit)              AS total_profit,
    AVG(le.lo_discount)         AS avg_discount,
    COUNT(DISTINCT le.lo_orderkey) AS distinct_orders,
    COUNT(*)                    AS lineorder_rows
FROM lineorder_enriched le
WHERE le.p_category = 'MFGR#12'
  AND le.c_region = 'ASIA'
GROUP BY le.order_year, le.c_region, le.p_category
ORDER BY le.order_year DESC, total_revenue DESC
