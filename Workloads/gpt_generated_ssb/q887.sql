WITH order_data AS (
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
        od.d_year AS order_year,
        od.d_date AS order_date,
        cd.d_date AS commit_date,
        c.c_region AS customer_region,
        c.c_mktsegment AS customer_marketsegment,
        p.p_category AS part_category,
        s.s_nation AS supplier_nation
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN dim_date cd
        ON lo.lo_commitdate = CAST(cd.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE CAST(od.d_date AS date) BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
      AND p.p_category = 'MFGR#14'
      AND s.s_nation = 'UNITED STATES'
      AND c.c_region = 'AMERICA'
),
aggregated AS (
    SELECT
        order_year,
        customer_region,
        customer_marketsegment,
        part_category,
        supplier_nation,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supply_cost,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        AVG(date_diff('day', CAST(order_date AS date), CAST(commit_date AS date))) AS avg_lead_time,
        COUNT(DISTINCT lo_orderkey) AS distinct_orders,
        SUM(lo_quantity) AS total_quantity
    FROM order_data
    GROUP BY order_year, customer_region, customer_marketsegment, part_category, supplier_nation
)
SELECT
    order_year,
    customer_region,
    customer_marketsegment,
    part_category,
    supplier_nation,
    total_revenue,
    total_supply_cost,
    total_profit,
    avg_discount,
    avg_lead_time,
    distinct_orders,
    total_quantity,
    RANK() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS revenue_rank
FROM aggregated
ORDER BY order_year, revenue_rank
