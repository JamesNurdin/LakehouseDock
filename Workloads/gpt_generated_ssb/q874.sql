WITH order_dim AS (
    -- Join lineorder to the date dimension on the order date surrogate key
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_orderdate,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        d.d_year,
        d.d_date
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(d.d_datekey AS INTEGER) = lo.lo_orderdate
),
joined_data AS (
    -- Enrich the order rows with customer region, part category and supplier region
    SELECT
        od.*,                         -- all columns from order_dim
        c.c_region   AS cust_region,
        p.p_category AS p_category,
        s.s_region   AS supp_region
    FROM order_dim od
    JOIN customer c ON od.lo_custkey = c.c_custkey
    JOIN part     p ON od.lo_partkey = p.p_partkey
    JOIN supplier s ON od.lo_suppkey = s.s_suppkey
),
agg AS (
    -- Aggregate revenue‑related metrics per year, supplier region and part category
    SELECT
        d_year,
        supp_region,
        p_category,
        SUM(lo_revenue)                         AS total_revenue,
        SUM(lo_revenue - lo_supplycost)         AS total_profit,
        AVG(lo_discount)                        AS avg_discount,
        COUNT(DISTINCT lo_orderkey)             AS num_orders
    FROM joined_data
    WHERE d_year BETWEEN '1993' AND '1995'
    GROUP BY d_year, supp_region, p_category
),
ranked AS (
    -- Rank part categories by revenue within each year‑supplier‑region bucket
    SELECT
        d_year,
        supp_region,
        p_category,
        total_revenue,
        total_profit,
        avg_discount,
        num_orders,
        ROW_NUMBER() OVER (PARTITION BY d_year, supp_region ORDER BY total_revenue DESC) AS revenue_rank
    FROM agg
)
SELECT
    d_year,
    supp_region,
    p_category,
    total_revenue,
    total_profit,
    avg_discount,
    num_orders,
    revenue_rank
FROM ranked
WHERE revenue_rank <= 3
ORDER BY d_year, supp_region, revenue_rank
