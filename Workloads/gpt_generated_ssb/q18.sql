WITH agg AS (
    SELECT
        od.d_year AS order_year,
        p.p_category AS part_category,
        s.s_region AS supplier_region,
        c.c_region AS customer_region,
        SUM(lo.lo_extendedprice) AS total_revenue,
        SUM(lo.lo_extendedprice - lo.lo_supplycost) AS total_profit,
        SUM(lo.lo_quantity) AS total_quantity,
        AVG(lo.lo_discount) AS avg_discount,
        COUNT(DISTINCT lo.lo_custkey) AS distinct_customers
    FROM lineorder lo
    JOIN dim_date od ON CAST(lo.lo_orderdate AS VARCHAR) = od.d_datekey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    GROUP BY od.d_year, p.p_category, s.s_region, c.c_region
),
ranked AS (
    SELECT
        order_year,
        part_category,
        supplier_region,
        customer_region,
        total_revenue,
        total_profit,
        total_quantity,
        avg_discount,
        distinct_customers,
        ROW_NUMBER() OVER (PARTITION BY order_year ORDER BY total_profit DESC) AS profit_rank
    FROM agg
    WHERE order_year = '1995'
)
SELECT
    order_year,
    part_category,
    supplier_region,
    customer_region,
    total_revenue,
    total_profit,
    total_quantity,
    avg_discount,
    distinct_customers,
    profit_rank
FROM ranked
WHERE profit_rank <= 5
ORDER BY profit_rank
