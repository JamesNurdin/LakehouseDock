WITH order_details AS (
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
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        d_order.d_year AS order_year,
        d_commit.d_year AS commit_year,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region,
        c.c_region AS customer_region,
        c.c_mktsegment
    FROM lineorder lo
    JOIN dim_date d_order   ON lo.lo_orderdate   = CAST(d_order.d_datekey   AS INTEGER)
    JOIN dim_date d_commit  ON lo.lo_commitdate  = CAST(d_commit.d_datekey  AS INTEGER)
    JOIN part p            ON lo.lo_partkey    = p.p_partkey
    JOIN supplier s        ON lo.lo_suppkey    = s.s_suppkey
    JOIN customer c        ON lo.lo_custkey    = c.c_custkey
    WHERE p.p_category = 'MFGR#12'
      AND s.s_region   = 'ASIA'
),

aggregated AS (
    SELECT
        order_year,
        supplier_region,
        SUM(lo_revenue)               AS total_revenue,
        SUM(lo_supplycost)            AS total_supply_cost,
        SUM(lo_revenue) - SUM(lo_supplycost) AS total_profit,
        AVG(lo_discount)              AS avg_discount,
        COUNT(*)                      AS order_count
    FROM order_details
    GROUP BY order_year, supplier_region
)

SELECT
    order_year,
    supplier_region,
    total_revenue,
    total_supply_cost,
    total_profit,
    avg_discount,
    order_count,
    ROW_NUMBER() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM aggregated
ORDER BY order_year, total_revenue DESC
LIMIT 100
