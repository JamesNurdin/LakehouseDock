WITH aggregated AS (
    SELECT
        s.s_region AS supplier_region,
        p.p_category AS p_category,
        od.d_month AS order_month,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount
    FROM lineorder lo
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date od
        ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date cd
        ON CAST(cd.d_datekey AS integer) = lo.lo_commitdate
    WHERE od.d_year = '1995'
      AND cd.d_year = '1995'
    GROUP BY s.s_region, p.p_category, od.d_month
)
SELECT
    supplier_region,
    p_category,
    order_month,
    total_revenue,
    total_supply_cost,
    total_revenue - total_supply_cost AS profit,
    total_quantity,
    avg_discount,
    RANK() OVER (PARTITION BY supplier_region ORDER BY total_revenue - total_supply_cost DESC) AS profit_rank
FROM aggregated
ORDER BY profit DESC
LIMIT 100
