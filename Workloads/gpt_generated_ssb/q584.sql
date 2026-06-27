WITH lo_joined AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_linenumber,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_quantity,
        lo.lo_extendedprice,
        lo.lo_ordertotalprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        lo.lo_shipmode,
        c.c_nation AS cust_nation,
        c.c_region AS cust_region,
        p.p_category AS part_category,
        p.p_brand1 AS part_brand,
        s.s_nation AS supp_nation,
        s.s_region AS supp_region
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    WHERE lo.lo_quantity > 5
      AND lo.lo_revenue > 0
),
agg AS (
    SELECT
        cust_nation,
        part_category,
        supp_region,
        SUM(lo_revenue) AS total_revenue,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_custkey) AS distinct_customers,
        COUNT(*) AS order_lines
    FROM lo_joined
    GROUP BY cust_nation, part_category, supp_region
)
SELECT
    cust_nation,
    part_category,
    supp_region,
    total_revenue,
    avg_discount,
    distinct_customers,
    order_lines,
    RANK() OVER (PARTITION BY cust_nation ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY cust_nation, revenue_rank
LIMIT 200
