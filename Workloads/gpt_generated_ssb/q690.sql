WITH supplier_year_profit AS (
    SELECT
        d_order.d_year,
        s.s_suppkey,
        s.s_name,
        s.s_region,
        SUM(lo.lo_revenue - lo.lo_supplycost) AS total_profit,
        SUM(lo.lo_revenue) AS total_revenue,
        SUM(lo.lo_supplycost) AS total_supply_cost,
        COUNT(DISTINCT lo.lo_orderkey) AS order_cnt
    FROM lineorder lo
    JOIN dim_date d_order
        ON CAST(d_order.d_datekey AS INTEGER) = lo.lo_orderdate
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    WHERE p.p_category = 'MFGR#2'
    GROUP BY d_order.d_year, s.s_suppkey, s.s_name, s.s_region
),
ranked_suppliers AS (
    SELECT
        d_year,
        s_name,
        s_region,
        total_profit,
        total_revenue,
        total_supply_cost,
        order_cnt,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS profit_rank
    FROM supplier_year_profit
)
SELECT
    d_year,
    s_name,
    s_region,
    total_profit,
    total_revenue,
    total_supply_cost,
    order_cnt,
    profit_rank
FROM ranked_suppliers
WHERE profit_rank <= 5
ORDER BY d_year, profit_rank
