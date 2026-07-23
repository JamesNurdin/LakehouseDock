WITH base AS (
  SELECT
    d.d_year,
    d.d_day_name,
    ca.ca_state,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    sr.sr_return_amt,
    sr.sr_return_tax,
    sr.sr_ticket_number,
    wr.wr_return_amt,
    inv.inv_quantity_on_hand,
    p.p_promo_name,
    p.p_cost,
    p.p_channel_email,
    p.p_channel_tv
  FROM tpcds.date_dim d
  JOIN tpcds.store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN tpcds.household_demographics hd
    ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN tpcds.customer_address ca
    ON sr.sr_addr_sk = ca.ca_address_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
   AND wr.wr_refunded_addr_sk = ca.ca_address_sk
  JOIN tpcds.inventory inv
    ON inv.inv_date_sk = d.d_date_sk
  JOIN tpcds.promotion p
    ON p.p_start_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND d.d_day_name = 'Tuesday'
    AND ca.ca_state = 'CA'
    AND ib.ib_lower_bound >= 50000
    AND sr.sr_return_amt > 100.00
    AND p.p_channel_email = 'N'
    AND wr.wr_return_amt < 500.00
)
SELECT
  base.d_year,
  base.ca_state,
  base.ib_income_band_sk,
  base.p_promo_name,
  COUNT(DISTINCT base.sr_ticket_number) AS cnt_store_tickets,
  SUM(base.sr_return_amt) AS total_store_return_amt,
  SUM(base.sr_return_tax) AS total_store_return_tax,
  SUM(base.wr_return_amt) AS total_web_return_amt,
  SUM(base.inv_quantity_on_hand) AS total_inventory_qty,
  AVG(base.p_cost) AS avg_promo_cost,
  (SELECT AVG(p2.p_cost) FROM tpcds.promotion p2) AS overall_avg_promo_cost,
  AVG(base.p_cost) / (SELECT AVG(p3.p_cost) FROM tpcds.promotion p3) AS promo_cost_ratio
FROM base
GROUP BY
  base.d_year,
  base.ca_state,
  base.ib_income_band_sk,
  base.p_promo_name
HAVING
  SUM(base.sr_return_amt) > 10000
  AND AVG(base.p_cost) > (SELECT AVG(p4.p_cost) FROM tpcds.promotion p4 WHERE p4.p_channel_tv = 'N')
ORDER BY total_store_return_amt DESC
LIMIT 100
