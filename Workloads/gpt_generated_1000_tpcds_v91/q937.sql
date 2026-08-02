WITH distinct_customers AS (
  SELECT DISTINCT
    c.c_customer_sk,
    ca.ca_city,
    ca.ca_state
  FROM customer c
  LEFT JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
),
base AS (
  SELECT
    sr.sr_ticket_number,
    sr.sr_return_amt,
    sr.sr_return_quantity,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    t.t_hour,
    t.t_minute,
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    c.c_customer_sk,
    c.c_first_name,
    c.c_last_name,
    r.r_reason_desc,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ca.ca_city AS sr_city,
    ca.ca_state AS sr_state
  FROM store_returns sr
  INNER JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  INNER JOIN time_dim t
    ON sr.sr_return_time_sk = t.t_time_sk
  INNER JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
  INNER JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
  INNER JOIN household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  INNER JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  LEFT JOIN customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
)
SELECT
  b.sr_ticket_number,
  b.d_date,
  b.t_hour,
  b.t_minute,
  b.i_item_id,
  b.i_product_name,
  b.i_current_price,
  b.c_first_name,
  b.c_last_name,
  dcu.ca_city AS current_city,
  dcu.ca_state AS current_state,
  b.sr_return_amt,
  b.sr_return_quantity,
  b.hd_buy_potential,
  b.ib_lower_bound,
  b.ib_upper_bound,
  b.r_reason_desc,
  cr.cust_total_return,
  cr.cust_return_count,
  cr.cust_distinct_items_returned,
  ROW_NUMBER() OVER (PARTITION BY b.d_date ORDER BY b.sr_return_amt DESC) AS daily_return_rank
FROM base b
LEFT JOIN distinct_customers dcu
  ON b.c_customer_sk = dcu.c_customer_sk
CROSS JOIN LATERAL (
  SELECT
    SUM(sr2.sr_return_amt) AS cust_total_return,
    COUNT(*) AS cust_return_count,
    COUNT(DISTINCT sr2.sr_item_sk) AS cust_distinct_items_returned
  FROM store_returns sr2
  WHERE sr2.sr_customer_sk = b.c_customer_sk
) cr
WHERE
  b.d_year = 2001
  AND b.t_hour BETWEEN 8 AND 12
  AND b.i_current_price > 50
  AND b.hd_buy_potential = '5001-10000'
  AND b.ib_lower_bound >= 20000
ORDER BY
  b.d_date DESC,
  daily_return_rank ASC
LIMIT 100
