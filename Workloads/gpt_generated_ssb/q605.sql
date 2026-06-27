WITH base AS (
    SELECT
        lo.lo_orderkey,
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
        CAST(d_order.d_datekey AS integer) AS order_date_key,
        d_order.d_year AS order_year,
        CAST(d_commit.d_datekey AS integer) AS commit_date_key,
        d_commit.d_year AS commit_year
    FROM lineorder lo
    JOIN dim_date d_order ON CAST(d_order.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_commit ON CAST(d_commit.d_datekey AS integer) = lo.lo_commitdate
),
filtered AS (
    SELECT
        b.lo_orderkey,
        b.lo_custkey,
        b.lo_partkey,
        b.lo_suppkey,
        b.lo_orderdate,
        b.lo_commitdate,
        b.lo_quantity,
        b.lo_extendedprice,
        b.lo_ordertotalprice,
        b.lo_discount,
        b.lo_revenue,
        b.lo_supplycost,
        b.lo_tax,
        b.lo_shipmode,
        b.order_year,
        b.commit_year,
        c.c_region
    FROM base b
    JOIN customer c ON b.lo_custkey = c.c_custkey
    JOIN part p ON b.lo_partkey = p.p_partkey
    JOIN supplier s ON b.lo_suppkey = s.s_suppkey
    WHERE p.p_category = 'MFGR#1'
      AND s.s_region = 'ASIA'
      AND b.commit_year = '1995'
),
part_rev AS (
    SELECT
        f.order_year,
        f.c_region,
        f.lo_partkey,
        SUM(f.lo_revenue) AS part_revenue
    FROM filtered f
    GROUP BY f.order_year, f.c_region, f.lo_partkey
),
ranked AS (
    SELECT
        pr.*, 
        RANK() OVER (PARTITION BY pr.order_year, pr.c_region ORDER BY pr.part_revenue DESC) AS revenue_rank
    FROM part_rev pr
)
SELECT
    r.order_year,
    r.c_region,
    r.lo_partkey,
    r.part_revenue,
    r.revenue_rank
FROM ranked r
WHERE r.revenue_rank <= 3
ORDER BY r.order_year, r.c_region, r.revenue_rank
