WITH agg AS (
  SELECT
    s.s_state,
    i.i_brand,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(sr.sr_return_amt) AS total_returns,
    SUM(cs.cs_ext_sales_price) - SUM(sr.sr_return_amt) AS net_sales,
    COUNT(DISTINCT cs.cs_order_number) AS orders,
    COUNT(DISTINCT sr.sr_ticket_number) AS returns
  FROM catalog_sales cs
  JOIN time_dim td_sold
    ON cs.cs_sold_time_sk = td_sold.t_time_sk
  JOIN customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN store_returns sr
    ON sr.sr_customer_sk = c.c_customer_sk
  JOIN time_dim td_return
    ON sr.sr_return_time_sk = td_return.t_time_sk
  JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  WHERE cs.cs_quantity > 2
    AND cs.cs_sales_price >= 50
    AND i.i_current_price BETWEEN 10 AND 500
    AND s.s_state IN ('CA', 'TX', 'NY')
    AND cd.cd_dep_employed_count >= 3
    AND sr.sr_return_tax < 20
    AND td_sold.t_hour BETWEEN 8 AND 20
  GROUP BY s.s_state, i.i_brand
  HAVING SUM(cs.cs_ext_sales_price) - SUM(sr.sr_return_amt) > 1000
)
SELECT
  s_state,
  i_brand,
  total_sales,
  total_returns,
  net_sales,
  orders,
  returns,
  SUM(net_sales) OVER (
    PARTITION BY s_state
    ORDER BY net_sales DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_state_sales
FROM agg
ORDER BY cumulative_state_sales DESC
LIMIT 100
