WITH lo_joined AS (
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
        c.c_region,
        c.c_nation,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region,
        od_order.d_year AS order_year,
        od_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date od_order
      ON CAST(lo.lo_orderdate AS VARCHAR) = od_order.d_datekey
    JOIN dim_date od_commit
      ON CAST(lo.lo_commitdate AS VARCHAR) = od_commit.d_datekey
    JOIN customer c
      ON lo.lo_custkey = c.c_custkey
    JOIN part p
      ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
      ON lo.lo_suppkey = s.s_suppkey
    WHERE od_order.d_year = '1998'
),
aggregated AS (
    SELECT
        order_year,
        c_region,
        p_category,
        COUNT(DISTINCT lo_orderkey) AS num_orders,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        SUM(lo_extendedprice * (1 - lo_discount / 100.0)) AS net_sales
    FROM lo_joined
    GROUP BY order_year, c_region, p_category
)
SELECT
    order_year,
    c_region,
    p_category,
    num_orders,
    total_revenue,
    total_profit,
    avg_discount,
    net_sales,
    ROW_NUMBER() OVER (PARTITION BY order_year ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
WHERE total_profit > 0
ORDER BY order_year, profit_rank
LIMIT 20
