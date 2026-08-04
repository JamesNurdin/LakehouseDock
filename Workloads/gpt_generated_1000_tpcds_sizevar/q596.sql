WITH
  sales AS (
    SELECT cs.*
    FROM catalog_sales cs
    WHERE cs.cs_quantity > 5
      AND cs.cs_ext_sales_price > 100
  ),
  returns AS (
    SELECT wr.*
    FROM web_returns wr
    WHERE wr.wr_return_amt > 50
  ),
  base AS (
    SELECT
      d_s.d_year AS d_year,
      t_s.t_hour AS t_hour,
      cp.cp_type AS cp_type,
      p.p_purpose AS p_purpose,
      c.c_preferred_cust_flag AS preferred_cust_flag,
      cd.cd_gender AS gender,
      s.s_state AS state,
      SUM(sales.cs_ext_sales_price) AS total_sales,
      SUM(sales.cs_net_profit) AS total_profit,
      COUNT(DISTINCT sales.cs_order_number) AS orders_cnt,
      SUM(returns.wr_return_amt) AS total_returns,
      CASE WHEN SUM(sales.cs_net_profit) > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_flag
    FROM sales
    JOIN date_dim d_s ON sales.cs_sold_date_sk = d_s.d_date_sk
    JOIN time_dim t_s ON sales.cs_sold_time_sk = t_s.t_time_sk
    JOIN catalog_page cp ON sales.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN promotion p ON sales.cs_promo_sk = p.p_promo_sk
    JOIN customer c ON sales.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON sales.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store s ON s.s_closed_date_sk = d_s.d_date_sk
    LEFT JOIN inventory inv ON inv.inv_date_sk = d_s.d_date_sk
    LEFT JOIN returns ON sales.cs_order_number = returns.wr_order_number
    LEFT JOIN reason r ON returns.wr_reason_sk = r.r_reason_sk
    GROUP BY d_s.d_year, t_s.t_hour, cp.cp_type, p.p_purpose, c.c_preferred_cust_flag, cd.cd_gender, s.s_state
  )
SELECT
  d_year,
  t_hour,
  profit_flag,
  total_sales,
  total_profit,
  orders_cnt,
  total_returns
FROM (
  SELECT d_year, t_hour, profit_flag, total_sales, total_profit, orders_cnt, total_returns
  FROM base
  WHERE profit_flag = 'Profitable'
  UNION
  SELECT d_year, t_hour, profit_flag, total_sales, total_profit, orders_cnt, total_returns
  FROM base
  WHERE total_returns > 0
) u
WHERE EXISTS (
  SELECT 1
  FROM promotion p2
  WHERE p2.p_purpose = 'Unknown'
    AND p2.p_discount_active = 'Y'
)
INTERSECT
SELECT d_year, t_hour, profit_flag, total_sales, total_profit, orders_cnt, total_returns
FROM base
WHERE total_sales > 1000
ORDER BY total_sales DESC
LIMIT 100
