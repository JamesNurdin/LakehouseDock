WITH return_agg AS (
  SELECT
    s.s_state AS state,
    c.c_customer_id AS customer_id,
    i.i_category AS category,
    t.t_shift AS shift,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(sr.sr_return_tax) AS total_return_tax,
    COUNT(DISTINCT sr.sr_ticket_number) AS distinct_tickets
  FROM store_returns sr
  INNER JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
  INNER JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
  INNER JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
  INNER JOIN customer_demographics cd
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
  WHERE
    t.t_shift = 'first'
    AND t.t_second > 5
    AND s.s_state = 'CA'
    AND i.i_wholesale_cost BETWEEN 5 AND 50
    AND c.c_preferred_cust_flag = 'Y'
    AND sr.sr_return_tax > 2.5
  GROUP BY
    s.s_state,
    c.c_customer_id,
    i.i_category,
    t.t_shift
),
state_summary AS (
  SELECT
    state,
    AVG(total_return_amount) AS avg_return_amount,
    SUM(total_return_tax) AS sum_return_tax,
    COUNT(DISTINCT customer_id) AS distinct_customers
  FROM return_agg
  GROUP BY state
  HAVING AVG(total_return_amount) > 1500
)
SELECT
  ra.state,
  ra.category,
  ra.total_return_amount,
  ra.total_return_tax,
  ra.distinct_tickets,
  ss.avg_return_amount,
  ROW_NUMBER() OVER (PARTITION BY ra.state ORDER BY ra.total_return_amount DESC) AS rn_state
FROM return_agg ra
JOIN state_summary ss
  ON ra.state = ss.state
WHERE ra.total_return_amount > 1000
ORDER BY ra.state, rn_state
LIMIT 100
