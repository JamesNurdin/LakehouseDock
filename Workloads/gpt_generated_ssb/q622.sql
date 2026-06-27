WITH yearly_supplier_profit AS (
  SELECT
    od.d_year,
    s.s_suppkey,
    s.s_name,
    s.s_region,
    p.p_category,
    sum(lo.lo_revenue - lo.lo_supplycost) AS profit,
    avg(lo.lo_discount) AS avg_discount,
    sum(lo.lo_quantity) AS total_quantity
  FROM lineorder lo
  JOIN dim_date od ON CAST(od.d_datekey AS integer) = lo.lo_orderdate
  JOIN part p ON lo.lo_partkey = p.p_partkey
  JOIN supplier s ON lo.lo_suppkey = s.s_suppkey
  WHERE od.d_year BETWEEN '1993' AND '1997'
    AND p.p_category = 'MFGR#1'
  GROUP BY od.d_year, s.s_suppkey, s.s_name, s.s_region, p.p_category
),
ranked_suppliers AS (
  SELECT
    ysp.*,
    rank() OVER (PARTITION BY ysp.d_year, ysp.s_region ORDER BY ysp.profit DESC) AS profit_rank
  FROM yearly_supplier_profit ysp
)
SELECT
  rs.d_year,
  rs.s_region,
  rs.s_suppkey,
  rs.s_name,
  rs.p_category,
  rs.profit,
  rs.avg_discount,
  rs.total_quantity,
  rs.profit_rank
FROM ranked_suppliers rs
WHERE rs.profit_rank <= 3
ORDER BY rs.d_year, rs.s_region, rs.profit_rank
