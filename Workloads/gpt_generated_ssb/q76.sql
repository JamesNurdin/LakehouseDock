WITH enriched AS (
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
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_tax,
        c.c_region,
        c.c_nation,
        c.c_mktsegment,
        p.p_category,
        p.p_brand1,
        s.s_region,
        s.s_nation,
        d_order.d_year,
        d_order.d_month,
        d_order.d_yearmonth,
        d_order.d_date AS order_date,
        d_commit.d_date AS commit_date
    FROM lineorder lo
    JOIN customer c ON lo.lo_custkey = c.c_custkey
    JOIN part p ON lo.lo_partkey = p.p_partkey
    JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
    JOIN dim_date d_order ON CAST(lo.lo_orderdate AS varchar) = d_order.d_datekey
    JOIN dim_date d_commit ON CAST(lo.lo_commitdate AS varchar) = d_commit.d_datekey
), agg AS (
    SELECT
        d_year,
        d_month,
        p_category,
        c_region,
        s_region,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        AVG(date_diff('day', date(commit_date), date(order_date))) AS avg_lead_time_days,
        SUM(lo_quantity) AS total_quantity
    FROM enriched
    GROUP BY d_year, d_month, p_category, c_region, s_region
)
SELECT
    d_year,
    d_month,
    p_category,
    c_region,
    s_region,
    total_revenue,
    total_profit,
    avg_discount,
    avg_lead_time_days,
    total_quantity,
    SUM(total_revenue) OVER (PARTITION BY d_year ORDER BY d_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_year_revenue,
    RANK() OVER (PARTITION BY d_year, d_month ORDER BY total_revenue DESC) AS revenue_rank
FROM agg
ORDER BY d_year, d_month, total_revenue DESC
LIMIT 200
