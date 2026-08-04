WITH
  sales_join AS (
    SELECT
      cs.cs_order_number,
      cs.cs_sold_date_sk,
      cs.cs_quantity,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cp.cp_department,
      cp.cp_type,
      sm.sm_type,
      sm.sm_code,
      w.w_warehouse_id,
      w.w_country,
      td.t_minute,
      td.t_shift,
      inv.inv_quantity_on_hand,
      ARRAY[cp.cp_type, sm.sm_type] AS type_array
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN inventory inv ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE cp.cp_department = 'Electronics'
      AND sm.sm_code = 'AIR'
      AND w.w_country = 'United States'
      AND td.t_minute IN (1, 5, 8)
      AND td.t_shift = 'second'
      AND inv.inv_quantity_on_hand > 500
  ),
  returns_join AS (
    SELECT
      wr.wr_order_number,
      wr.wr_return_amt,
      wr.wr_net_loss,
      td.t_minute AS ret_minute,
      hd.hd_dep_count
    FROM web_returns wr
    JOIN time_dim td ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN household_demographics hd ON wr.wr_returning_hdemo_sk = hd.hd_demo_sk
    WHERE wr.wr_return_ship_cost > 100
  ),
  order_sales AS (
    SELECT cs_order_number FROM catalog_sales
  ),
  order_returns AS (
    SELECT wr_order_number FROM web_returns
  ),
  except_orders AS (
    SELECT cs_order_number FROM order_sales
    EXCEPT
    SELECT wr_order_number FROM order_returns
  ),
  intersect_orders AS (
    SELECT cs_order_number FROM order_sales
    INTERSECT
    SELECT wr_order_number FROM order_returns
  ),
  agg AS (
    SELECT
      cp_department,
      SUM(cs_ext_sales_price) AS total_sales,
      AVG(cs_net_profit) AS avg_profit,
      COUNT(DISTINCT cs_order_number) AS distinct_orders,
      MIN(cs_sold_date_sk) AS min_sold_date_sk,
      MAX(cs_sold_date_sk) AS max_sold_date_sk
    FROM sales_join
    GROUP BY cp_department
  ),
  ranked AS (
    SELECT
      a.*,
      ROW_NUMBER() OVER (PARTITION BY a.cp_department ORDER BY a.total_sales DESC) AS dept_rank
    FROM agg a
  )
SELECT
  r.cp_department,
  r.total_sales,
  r.avg_profit,
  r.distinct_orders,
  r.min_sold_date_sk,
  r.max_sold_date_sk,
  r.dept_rank,
  t.type_element,
  (SELECT COUNT(*) FROM except_orders) AS except_order_count,
  (SELECT COUNT(*) FROM intersect_orders) AS intersect_order_count
FROM ranked r
JOIN sales_join sj ON sj.cp_department = r.cp_department
JOIN returns_join rj ON sj.t_minute = rj.ret_minute
CROSS JOIN UNNEST(sj.type_array) AS t(type_element)
ORDER BY r.total_sales DESC
OFFSET 0
FETCH NEXT 100 ROWS ONLY
