WITH
  sampled_sales AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
  ),
  intersect_orders AS (
    SELECT cs.cs_order_number AS order_key
    FROM catalog_sales cs
    INTERSECT
    SELECT sr.sr_ticket_number AS order_key
    FROM store_returns sr
  ),
  sales_agg AS (
    SELECT
      cc.cc_name,
      cp.cp_department,
      d.d_year,
      d.d_month_seq,
      SUM(cs.cs_ext_sales_price) AS total_sales,
      SUM(cs.cs_net_profit) AS total_profit,
      AVG(cs.cs_quantity) AS avg_quantity,
      COUNT(DISTINCT cs.cs_order_number) AS order_cnt
    FROM sampled_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1 AND 12
      AND cs.cs_quantity > 5
      AND cs.cs_sales_price > 100
      AND ca.ca_state = 'CA'
      AND cd.cd_gender = 'M'
      AND cs.cs_order_number IN (SELECT order_key FROM intersect_orders)
    GROUP BY cc.cc_name, cp.cp_department, d.d_year, d.d_month_seq
  ),
  store_returns_agg AS (
    SELECT
      cc.cc_name,
      cp.cp_department,
      d.d_year,
      d.d_month_seq,
      SUM(sr.sr_return_amt) AS total_sales,
      SUM(-sr.sr_net_loss) AS total_profit,
      AVG(sr.sr_return_quantity) AS avg_quantity,
      COUNT(DISTINCT sr.sr_ticket_number) AS order_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON d.d_date_sk = cc.cc_closed_date_sk
    JOIN catalog_page cp ON d.d_date_sk = cp.cp_start_date_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1 AND 12
      AND sr.sr_return_quantity > 2
      AND sr.sr_return_amt > 50
      AND r.r_reason_desc LIKE '%color%'
      AND sr.sr_ticket_number IN (SELECT order_key FROM intersect_orders)
    GROUP BY cc.cc_name, cp.cp_department, d.d_year, d.d_month_seq
  ),
  web_returns_agg AS (
    SELECT
      cc.cc_name,
      cp.cp_department,
      d.d_year,
      d.d_month_seq,
      SUM(wr.wr_return_amt) AS total_sales,
      SUM(-wr.wr_net_loss) AS total_profit,
      AVG(wr.wr_return_quantity) AS avg_quantity,
      COUNT(DISTINCT wr.wr_order_number) AS order_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN call_center cc ON d.d_date_sk = cc.cc_open_date_sk
    JOIN catalog_page cp ON d.d_date_sk = cp.cp_end_date_sk
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_site ws ON d.d_date_sk = ws.web_open_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1 AND 12
      AND wr.wr_return_quantity > 2
      AND wr.wr_return_amt > 50
      AND ws.web_state = 'CA'
      AND r.r_reason_desc LIKE '%color%'
      AND wr.wr_order_number IN (SELECT order_key FROM intersect_orders)
    GROUP BY cc.cc_name, cp.cp_department, d.d_year, d.d_month_seq
  ),
  union_agg AS (
    SELECT * FROM sales_agg
    UNION
    SELECT * FROM store_returns_agg
    UNION
    SELECT * FROM web_returns_agg
  ),
  final AS (
    SELECT
      u.cc_name,
      u.cp_department,
      u.d_year,
      u.d_month_seq,
      SUM(u.total_sales) AS sum_sales,
      SUM(u.total_profit) AS sum_profit,
      AVG(u.avg_quantity) AS avg_quantity,
      SUM(u.order_cnt) AS total_orders,
      ROW_NUMBER() OVER (ORDER BY SUM(u.total_profit) DESC) AS row_num
    FROM union_agg u
    GROUP BY u.cc_name, u.cp_department, u.d_year, u.d_month_seq
  )
SELECT *
FROM final
ORDER BY sum_profit DESC
LIMIT 100
