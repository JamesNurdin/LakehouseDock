WITH sales AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_quantity,
    cs.cs_net_profit,
    cs.cs_bill_addr_sk,
    d_sold.d_year,
    d_sold.d_quarter_seq,
    hd.hd_buy_potential,
    ca.ca_state,
    sm.sm_type,
    p.p_promo_name,
    p.p_discount_active
  FROM catalog_sales cs
  JOIN date_dim d_sold
    ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT OUTER JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  WHERE d_sold.d_year = 2001
    AND cs.cs_quantity > 1
    AND hd.hd_buy_potential = '1001-5000'
    AND ca.ca_state = 'CA'
    AND (p.p_discount_active = 'Y' OR p.p_discount_active IS NULL)
),
returns AS (
  SELECT
    sr.sr_returned_date_sk,
    sr.sr_hdemo_sk,
    sr.sr_addr_sk,
    sr.sr_return_amt,
    d_ret.d_year AS return_year,
    hd_ret.hd_buy_potential AS return_buy_potential,
    ca_ret.ca_state AS return_state
  FROM store_returns sr
  JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
  JOIN household_demographics hd_ret
    ON sr.sr_hdemo_sk = hd_ret.hd_demo_sk
  JOIN customer_address ca_ret
    ON sr.sr_addr_sk = ca_ret.ca_address_sk
  WHERE d_ret.d_year BETWEEN 2000 AND 2002
)
SELECT
  s.cs_order_number,
  s.cs_sold_date_sk,
  s.d_year,
  s.ca_state,
  s.sm_type,
  s.cs_quantity,
  s.cs_net_profit,
  s.p_promo_name,
  r.sr_return_amt,
  SUM(s.cs_net_profit) OVER (PARTITION BY s.ca_state, s.d_year) AS state_year_total_profit,
  RANK() OVER (PARTITION BY s.ca_state, s.d_year ORDER BY s.cs_net_profit DESC) AS profit_rank,
  (
    SELECT AVG(sr2.sr_return_amt)
    FROM store_returns sr2
    JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
    WHERE d2.d_year = s.d_year
      AND sr2.sr_addr_sk = s.cs_bill_addr_sk
  ) AS avg_return_amt_state_year
FROM sales s
LEFT JOIN returns r
  ON r.sr_returned_date_sk = s.cs_sold_date_sk
  AND r.return_state = s.ca_state
WHERE s.cs_net_profit > 0
ORDER BY s.d_year, s.ca_state, profit_rank
LIMIT 100
