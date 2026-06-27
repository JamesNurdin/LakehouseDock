WITH filtered_orders AS (
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
        lo.lo_discount,
        lo.lo_supplycost,
        lo.lo_revenue,
        lo.lo_tax,
        od.d_year
    FROM lineorder lo
    JOIN dim_date od
        ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    WHERE od.d_year = '1998'
),
order_customer AS (
    SELECT
        fo.*,
        c.c_region,
        c.c_nation,
        c.c_mktsegment
    FROM filtered_orders fo
    JOIN customer c
        ON fo.lo_custkey = c.c_custkey
),
order_part AS (
    SELECT
        oc.*,
        p.p_category,
        p.p_brand1,
        p.p_mfgr
    FROM order_customer oc
    JOIN part p
        ON oc.lo_partkey = p.p_partkey
),
aggregated AS (
    SELECT
        op.c_region,
        op.p_category,
        SUM(op.lo_extendedprice * (1 - op.lo_discount / 100.0)) AS total_sales,
        SUM(op.lo_extendedprice * (1 - op.lo_discount / 100.0) - op.lo_supplycost) AS total_profit,
        AVG(op.lo_discount) AS avg_discount,
        COUNT(DISTINCT op.lo_orderkey) AS order_cnt
    FROM order_part op
    GROUP BY op.c_region, op.p_category
)
SELECT
    a.c_region,
    a.p_category,
    a.total_sales,
    a.total_profit,
    a.avg_discount,
    a.order_cnt,
    RANK() OVER (PARTITION BY a.c_region ORDER BY a.total_sales DESC) AS revenue_rank
FROM aggregated a
ORDER BY a.c_region, a.total_sales DESC
