WITH supplier_year_summary AS (
    SELECT
        d.d_year AS year,
        s.s_suppkey AS suppkey,
        s.s_name AS supp_name,
        s.s_region AS supp_region,
        sum(lo.lo_revenue) AS total_revenue,
        sum(lo.lo_supplycost) AS total_supplycost,
        count(DISTINCT lo.lo_orderkey) AS order_count
    FROM lineorder lo
    JOIN dim_date d
        ON lo.lo_orderdate = cast(d.d_datekey AS integer)
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    WHERE d.d_year IN ('1995', '1996', '1997')
    GROUP BY d.d_year, s.s_suppkey, s.s_name, s.s_region
),
ranked_suppliers AS (
    SELECT
        year,
        suppkey,
        supp_name,
        supp_region,
        total_revenue,
        total_supplycost,
        (total_revenue - total_supplycost) AS profit,
        order_count,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY total_revenue DESC) AS revenue_rank
    FROM supplier_year_summary
)
SELECT
    year,
    suppkey,
    supp_name,
    supp_region,
    total_revenue,
    total_supplycost,
    profit,
    order_count,
    revenue_rank
FROM ranked_suppliers
WHERE revenue_rank <= 5
ORDER BY year, revenue_rank
