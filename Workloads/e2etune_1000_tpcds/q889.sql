WITH returns_promo AS (
  SELECT
    sr.sr_returned_date_sk,
    sr.sr_return_amt,
    sr.sr_item_sk,
    sr.sr_addr_sk,
    p.p_promo_sk,
    p.p_promo_name,
    p.p_cost,
    i.i_category,
    i.i_brand,
    d_ret.d_year,
    d_ret.d_month_seq,
    d_ret.d_date
  FROM store_returns sr
  JOIN date_dim d_ret
    ON sr.sr_returned_date_sk = d_ret.d_date_sk
  JOIN promotion p
    ON sr.sr_item_sk = p.p_item_sk
   AND d_ret.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
   AND p.p_discount_active = 'Y'
  JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
)
SELECT
  cc.cc_name,
  rp.d_year,
  rp.d_month_seq,
  COUNT(DISTINCT rp.p_promo_sk) AS promo_count,
  SUM(rp.sr_return_amt) AS total_return_amt,
  SUM(rp.p_cost) AS total_promo_cost,
  AVG(rp.sr_return_amt) AS avg_return_amt,
  RANK() OVER (PARTITION BY rp.d_year, rp.d_month_seq ORDER BY SUM(rp.sr_return_amt) DESC) AS return_rank
FROM returns_promo rp
JOIN call_center cc
  ON rp.sr_returned_date_sk BETWEEN cc.cc_open_date_sk AND cc.cc_closed_date_sk
JOIN customer_address ca
  ON rp.sr_addr_sk = ca.ca_address_sk
JOIN date_dim d_open
  ON cc.cc_open_date_sk = d_open.d_date_sk
JOIN date_dim d_closed
  ON cc.cc_closed_date_sk = d_closed.d_date_sk
WHERE
  cc.cc_company = 1
  AND cc.cc_class = 'large'
  AND ca.ca_state = 'CA'
  AND d_open.d_date <= rp.d_date
  AND d_closed.d_date >= rp.d_date
GROUP BY
  cc.cc_name,
  rp.d_year,
  rp.d_month_seq
HAVING
  SUM(rp.sr_return_amt) > 1000
ORDER BY
  total_return_amt DESC
LIMIT 100
