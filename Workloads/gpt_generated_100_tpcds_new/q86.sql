WITH joined AS (
  SELECT
    cc.cc_name,
    cc.cc_state,
    d.d_year,
    d.d_quarter_name,
    t.t_hour,
    wp.wp_type,
    ca.ca_state,
    wr.wr_return_amt,
    wr.wr_return_tax,
    wr.wr_order_number
  FROM web_returns wr
  LEFT JOIN date_dim d
    ON wr.wr_returned_date_sk = d.d_date_sk
  LEFT JOIN time_dim t
    ON wr.wr_returned_time_sk = t.t_time_sk
  LEFT JOIN customer_address ca
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
  LEFT JOIN customer_demographics cd
    ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  LEFT JOIN call_center cc
    ON cc.cc_closed_date_sk = d.d_date_sk
  LEFT JOIN date_dim d2
    ON wp.wp_creation_date_sk = d2.d_date_sk
  WHERE d.d_year = 2001
    AND d.d_quarter_name = '1903Q3'
    AND t.t_hour = 10
    AND wr.wr_return_amt > 200.00
    AND wp.wp_type = 'article'
    AND cc.cc_state = 'CA'
    AND ca.ca_state = 'CA'
),
agg AS (
  SELECT
    cc_name,
    cc_state,
    d_year,
    wp_type,
    ca_state,
    SUM(wr_return_amt) AS total_return_amt,
    AVG(wr_return_tax) AS avg_return_tax,
    COUNT(DISTINCT wr_order_number) AS distinct_orders
  FROM joined
  GROUP BY cc_name, cc_state, d_year, wp_type, ca_state
)
SELECT
  a.cc_name,
  a.cc_state,
  a.d_year,
  a.wp_type,
  a.ca_state,
  a.total_return_amt,
  a.avg_return_tax,
  a.distinct_orders,
  ROW_NUMBER() OVER (PARTITION BY a.cc_name ORDER BY a.total_return_amt DESC) AS rn,
  ds.ref_date
FROM agg a
CROSS JOIN (
  SELECT DATE '2023-01-01' AS ref_date UNION ALL SELECT DATE '2023-01-02' AS ref_date
) ds
ORDER BY a.total_return_amt DESC
LIMIT 100
