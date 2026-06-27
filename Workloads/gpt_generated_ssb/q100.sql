WITH order_dates AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_extendedprice,
        lo.lo_discount,
        lo.lo_revenue,
        lo.lo_supplycost,
        CAST(lo.lo_orderdate AS varchar) AS order_date_key,
        CAST(lo.lo_commitdate AS varchar) AS commit_date_key,
        d_ord.d_year AS order_year,
        d_ord.d_month AS order_month,
        d_com.d_year AS commit_year,
        d_com.d_month AS commit_month
    FROM lineorder lo
    JOIN dim_date d_ord
        ON CAST(lo.lo_orderdate AS varchar) = d_ord.d_datekey
    JOIN dim_date d_com
        ON CAST(lo.lo_commitdate AS varchar) = d_com.d_datekey
),
agg AS (
    SELECT
        od.order_year,
        od.order_month,
        cust.c_region,
        supp.s_nation,
        part.p_category,
        SUM(od.lo_revenue) AS total_revenue,
        SUM(od.lo_extendedprice) AS total_extended_price,
        SUM(od.lo_supplycost) AS total_supply_cost,
        SUM(od.lo_extendedprice - od.lo_supplycost) AS total_profit,
        COUNT(DISTINCT od.lo_orderkey) AS distinct_orders,
        AVG(od.lo_discount) AS avg_discount,
        SUM(CASE WHEN od.commit_year > od.order_year THEN 1 ELSE 0 END) AS orders_committed_later
    FROM order_dates od
    JOIN customer cust
        ON od.lo_custkey = cust.c_custkey
    JOIN part
        ON od.lo_partkey = part.p_partkey
    JOIN supplier supp
        ON od.lo_suppkey = supp.s_suppkey
    WHERE cust.c_region = 'ASIA'
    GROUP BY
        od.order_year,
        od.order_month,
        cust.c_region,
        supp.s_nation,
        part.p_category
)
SELECT
    agg.order_year,
    agg.order_month,
    agg.c_region,
    agg.s_nation,
    agg.p_category,
    agg.total_revenue,
    agg.total_extended_price,
    agg.total_supply_cost,
    agg.total_profit,
    agg.distinct_orders,
    agg.avg_discount,
    agg.orders_committed_later,
    SUM(agg.total_revenue) OVER (
        PARTITION BY agg.c_region
        ORDER BY agg.order_year, agg.order_month
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM agg
ORDER BY
    agg.order_year,
    agg.order_month,
    agg.total_revenue DESC
