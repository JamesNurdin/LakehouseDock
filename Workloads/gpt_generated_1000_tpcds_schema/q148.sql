WITH
  sales_agg AS (
    SELECT
      ca.ca_state AS state,
      SUM(cs.cs_net_profit) AS total_sales_profit,
      COUNT(*) AS sales_cnt
    FROM
      catalog_sales cs
      JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
      JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE
      regexp_like(ca.ca_suite_number, '^Suite [A-Z]')
      AND ca.ca_street_name LIKE 'L%'
    GROUP BY
      ca.ca_state
  ),
  returns_agg AS (
    SELECT
      ca.ca_state AS state,
      SUM(sr.sr_return_amt) AS total_return_amt,
      COUNT(*) AS returns_cnt
    FROM
      store_returns sr
      JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
      JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE
      regexp_like(ca.ca_suite_number, '^Suite [A-Z]')
      AND ca.ca_street_name LIKE 'L%'
    GROUP BY
      ca.ca_state
  )
SELECT
  COALESCE(s.state, r.state) AS state,
  s.total_sales_profit,
  r.total_return_amt,
  s.sales_cnt,
  r.returns_cnt,
  SUM(COALESCE(s.total_sales_profit, 0)) OVER (ORDER BY COALESCE(s.state, r.state) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_sales_profit,
  SUM(COALESCE(r.total_return_amt, 0)) OVER (ORDER BY COALESCE(s.state, r.state) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_return_amt
FROM
  sales_agg s
  FULL OUTER JOIN returns_agg r ON s.state = r.state
ORDER BY
  state
LIMIT 100
