-- Revenue, profit and discount analysis by year, supplier nation and part category
WITH base AS (
    SELECT
        CAST(lo.lo_orderdate AS VARCHAR) AS order_date_key,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        s.s_nation,
        p.p_category,
        d.d_year
    FROM lineorder lo
    JOIN dim_date d
        ON CAST(lo.lo_orderdate AS VARCHAR) = d.d_datekey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE d.d_year BETWEEN '1997' AND '1998'
),
agg AS (
    SELECT
        d_year,
        s_nation,
        p_category,
        sum(lo_revenue) AS total_revenue,
        sum(lo_revenue - lo_supplycost) AS total_profit,
        avg(lo_discount) AS avg_discount
    FROM base
    GROUP BY d_year, s_nation, p_category
)
SELECT
    d_year,
    s_nation,
    p_category,
    total_revenue,
    total_profit,
    avg_discount,
    total_revenue * 1.0 / sum(total_revenue) OVER (PARTITION BY d_year, s_nation) AS revenue_share
FROM agg
ORDER BY d_year, s_nation, p_category
