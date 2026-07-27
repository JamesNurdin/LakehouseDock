WITH returns_detail AS (
  SELECT
    sr.sr_customer_sk,
    c.c_first_name,
    c.c_last_name,
    c.c_preferred_cust_flag,
    sr.sr_return_amt,
    i.i_item_id,
    i.i_current_price,
    p.p_promo_name,
    p.p_channel_email,
    inv.inv_quantity_on_hand,
    hd.hd_dep_count,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    CASE
      WHEN sr.sr_return_amt > 1000 THEN 'HIGH'
      ELSE 'NORMAL'
    END AS return_category
  FROM store_returns sr
  JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
  JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  JOIN customer c
    ON sr.sr_customer_sk = c.c_customer_sk
  JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  WHERE p.p_channel_email = 'Y'
    AND p.p_channel_dmail = 'N'
    AND ib.ib_upper_bound >= 30000
    AND i.i_current_price BETWEEN 10 AND 500
    AND inv.inv_quantity_on_hand > 0
    AND c.c_preferred_cust_flag = 'Y'
)
SELECT
  rd.sr_customer_sk,
  rd.c_first_name,
  rd.c_last_name,
  rd.return_category,
  rd.sr_return_amt,
  rd.i_item_id,
  rd.i_current_price,
  rd.p_promo_name,
  rd.hd_dep_count,
  rd.ib_lower_bound,
  rd.ib_upper_bound,
  SUM(rd.sr_return_amt) OVER (
    PARTITION BY rd.sr_customer_sk
    ORDER BY rd.sr_return_amt DESC
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_return,
  RANK() OVER (
    PARTITION BY rd.sr_customer_sk
    ORDER BY rd.sr_return_amt DESC
  ) AS return_rank
FROM returns_detail rd
ORDER BY rd.sr_return_amt DESC
LIMIT 100
