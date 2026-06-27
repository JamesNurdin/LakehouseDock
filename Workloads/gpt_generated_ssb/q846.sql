WITH joined_data AS (
    SELECT
        lo.lo_orderkey,
        lo.lo_extendedprice,
        lo.lo_revenue,
        lo.lo_supplycost,
        lo.lo_discount,
        lo.lo_quantity,
        lo.lo_tax,
        lo.lo_shipmode,
        p.p_category,
        p.p_brand1,
        s.s_region AS supplier_region,
        c.c_region AS customer_region,
        CAST(d_ord.d_datekey AS integer) AS order_date_sk,
        CAST(d_com.d_datekey AS integer) AS commit_date_sk,
        d_ord.d_year AS order_year,
        d_com.d_year AS commit_year
    FROM lineorder lo
    JOIN part p
        ON lo.lo_partkey = p.p_partkey
    JOIN supplier s
        ON lo.lo_suppkey = s.s_suppkey
    JOIN customer c
        ON lo.lo_custkey = c.c_custkey
    JOIN dim_date d_ord
        ON CAST(d_ord.d_datekey AS integer) = lo.lo_orderdate
    JOIN dim_date d_com
        ON CAST(d_com.d_datekey AS integer) = lo.lo_commitdate
    WHERE d_ord.d_year = '1997'
      AND p.p_category = 'MFGR#12'
),
aggregated AS (
    SELECT
        order_year,
        supplier_region,
        SUM(lo_extendedprice) AS total_extended_price,
        SUM(lo_revenue) AS total_revenue,
        SUM(lo_revenue - lo_supplycost) AS total_profit,
        AVG(lo_discount) AS avg_discount,
        COUNT(DISTINCT lo_orderkey) AS order_cnt
    FROM joined_data
    GROUP BY order_year, supplier_region
)
SELECT
    order_year,
    supplier_region,
    total_revenue,
    total_profit,
    total_extended_price,
    avg_discount,
    order_cnt,
    RANK() OVER (PARTITION BY order_year ORDER BY total_profit DESC) AS profit_rank
FROM aggregated
ORDER BY order_year, profit_rank
LIMIT 20
