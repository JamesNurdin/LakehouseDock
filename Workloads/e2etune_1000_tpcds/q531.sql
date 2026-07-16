WITH sales_agg AS (
  SELECT
    cc.cc_call_center_id AS cc_id,
    cc.cc_state,
    cs.cs_sold_date_sk AS sold_date_key,
    SUM(cs.cs_net_profit) AS total_net_profit,
    COALESCE(SUM(wr.wr_net_loss), 0) AS total_return_loss,
    SUM(cs.cs_net_profit) - COALESCE(SUM(wr.wr_net_loss), 0) AS net_profit_after_returns,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(*) AS total_sales
  FROM catalog_sales cs
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
  JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
  LEFT JOIN web_returns wr
    ON wr.wr_refunded_customer_sk = c.c_customer_sk
   AND wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE cc.cc_company = 1
    AND cc.cc_market_manager = 'Julius Tran'
    AND cs.cs_sold_date_sk BETWEEN 2458849 AND 2459213
  GROUP BY
    cc.cc_call_center_id,
    cc.cc_state,
    cs.cs_sold_date_sk
  HAVING SUM(cs.cs_net_profit) > 10000
)
SELECT
  cc_id,
  cc_state,
  sold_date_key,
  total_net_profit,
  total_return_loss,
  net_profit_after_returns,
  distinct_orders,
  total_sales,
  RANK() OVER (PARTITION BY sold_date_key ORDER BY net_profit_after_returns DESC) AS profit_rank
FROM sales_agg
ORDER BY net_profit_after_returns DESC
LIMIT 100
