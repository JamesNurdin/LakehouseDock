WITH filtered_orders AS (
    SELECT
        lo.lo_custkey,
        lo.lo_partkey,
        lo.lo_suppkey,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        CAST(od.d_datekey AS integer) AS order_date_key,
        od.d_year AS order_year,
        c.c_mktsegment
    FROM lineorder lo
    JOIN dim_date od
        ON lo.lo_orderdate = CAST(od.d_datekey AS integer)
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    WHERE od.d_year = '1995'
      AND c.c_mktsegment = 'AUTOMOBILE'
),
agg_supplier AS (
    SELECT
        s.s_name AS supplier_name,
        s.s_region,
        f.order_year,
        SUM(f.lo_revenue) AS total_revenue,
        SUM(f.lo_supplycost) AS total_supply_cost,
        SUM(f.lo_revenue - f.lo_supplycost) AS profit,
        AVG(f.lo_discount) AS avg_discount
    FROM filtered_orders f
    JOIN part p
        ON f.lo_partkey = p.p_partkey
    JOIN supplier s
        ON f.lo_suppkey = s.s_suppkey
    WHERE p.p_category = 'MFGR#12'
    GROUP BY s.s_name, s.s_region, f.order_year
),
ranked_supplier AS (
    SELECT
        supplier_name,
        s_region,
        order_year,
        total_revenue,
        total_supply_cost,
        profit,
        avg_discount,
        ROW_NUMBER() OVER (PARTITION BY s_region ORDER BY profit DESC) AS region_rank
    FROM agg_supplier
)
SELECT
    supplier_name,
    s_region,
    order_year,
    total_revenue,
    total_supply_cost,
    profit,
    avg_discount
FROM ranked_supplier
WHERE region_rank <= 5
ORDER BY s_region, profit DESC
