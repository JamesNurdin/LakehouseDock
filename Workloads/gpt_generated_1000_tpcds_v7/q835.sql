WITH sales_agg AS (
  SELECT 
    ca.ca_state,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(ss.ss_net_profit) AS total_profit
  FROM tpcds.store_sales ss
  JOIN tpcds.customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
  WHERE ss.ss_ext_sales_price > 1000
    AND ss.ss_quantity BETWEEN 1 AND 10
    AND ca.ca_state IN ('CA', 'TX', 'NY', 'FL', 'WA')
    AND ca.ca_gmt_offset BETWEEN -5.00 AND 5.00
  GROUP BY ca.ca_state
),
returns_agg AS (
  SELECT 
    ca.ca_state,
    SUM(wr.wr_return_amt_inc_tax) AS total_return_amount,
    SUM(wr.wr_net_loss) AS total_loss
  FROM tpcds.web_returns wr
  JOIN tpcds.customer_address ca ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  WHERE wr.wr_return_tax > 10
    AND wr.wr_reversed_charge < 300
    AND ca.ca_state IN ('CA', 'TX', 'NY', 'FL', 'WA')
  GROUP BY ca.ca_state
)
SELECT
  s.ca_state,
  s.total_sales,
  s.total_profit,
  r.total_return_amount,
  r.total_loss,
  (s.total_profit - r.total_loss) AS net_score,
  RANK() OVER (ORDER BY (s.total_profit - r.total_loss) DESC) AS profit_rank,
  ROW_NUMBER() OVER (PARTITION BY s.ca_state ORDER BY s.total_sales DESC) AS sales_rownum
FROM sales_agg s
JOIN returns_agg r ON s.ca_state = r.ca_state
ORDER BY net_score DESC
LIMIT 20
