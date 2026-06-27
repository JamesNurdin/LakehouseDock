WITH order_base AS (
    SELECT
        dim_order.d_year AS order_year,
        supplier.s_nation AS supp_nation,
        part.p_category AS part_category,
        lineorder.lo_revenue,
        lineorder.lo_supplycost,
        lineorder.lo_tax,
        lineorder.lo_discount
    FROM lineorder
    JOIN dim_date AS dim_order
        ON CAST(dim_order.d_datekey AS integer) = lineorder.lo_orderdate
    JOIN dim_date AS dim_commit
        ON CAST(dim_commit.d_datekey AS integer) = lineorder.lo_commitdate
    JOIN customer
        ON lineorder.lo_custkey = customer.c_custkey
    JOIN supplier
        ON lineorder.lo_suppkey = supplier.s_suppkey
    JOIN part
        ON lineorder.lo_partkey = part.p_partkey
    WHERE dim_order.d_date >= '1992-01-01'
      AND dim_order.d_date <= '1997-12-31'
      AND dim_commit.d_date >= dim_order.d_date
),
aggregated AS (
    SELECT
        order_year,
        supp_nation,
        part_category,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_supplycost) AS total_supplycost,
        SUM(lo_tax) AS total_tax,
        AVG(lo_discount) AS avg_discount,
        COUNT(*) AS order_cnt,
        (SUM(lo_revenue) - SUM(lo_supplycost) - SUM(lo_tax)) AS profit
    FROM order_base
    GROUP BY order_year, supp_nation, part_category
),
ranked AS (
    SELECT
        order_year,
        supp_nation,
        part_category,
        total_revenue,
        total_supplycost,
        total_tax,
        avg_discount,
        order_cnt,
        profit,
        ROW_NUMBER() OVER (PARTITION BY order_year ORDER BY total_revenue DESC) AS rn
    FROM aggregated
)
SELECT
    order_year,
    supp_nation,
    part_category,
    total_revenue,
    total_supplycost,
    total_tax,
    avg_discount,
    order_cnt,
    profit
FROM ranked
WHERE rn <= 5
ORDER BY order_year, total_revenue DESC
