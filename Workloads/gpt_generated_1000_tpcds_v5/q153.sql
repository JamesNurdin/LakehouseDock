WITH base AS (
  SELECT
    d.d_year,
    d.d_month_seq,
    i.i_brand,
    i.i_category,
    i.i_current_price,
    inv.inv_quantity_on_hand,
    p.p_cost,
    r.r_reason_desc,
    s.s_state,
    w.web_country,
    sr.sr_return_amt,
    sr.sr_return_quantity,
    sr.sr_ticket_number,
    CASE WHEN s.s_state = 'CA' THEN 'West' ELSE 'Other' END AS region_flag
  FROM store_returns sr
  JOIN date_dim d
    ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN item i
    ON sr.sr_item_sk = i.i_item_sk
  JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
  JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
   AND p.p_start_date_sk = d.d_date_sk
  JOIN reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN store s
    ON sr.sr_store_sk = s.s_store_sk
   AND s.s_closed_date_sk = d.d_date_sk
  JOIN web_site w
    ON w.web_open_date_sk = d.d_date_sk
  WHERE d.d_year = 2001
    AND d.d_month_seq BETWEEN 1200 AND 1211
    AND i.i_current_price > 50
    AND inv.inv_quantity_on_hand < 200
    AND p.p_cost > 500
    AND r.r_reason_desc LIKE '%size%'
    AND s.s_state = 'CA'
    AND w.web_country = 'United States'
)
SELECT
  d_year,
  i_brand,
  i_category,
  region_flag,
  r_reason_desc,
  COUNT(DISTINCT sr_ticket_number) AS cnt_tickets,
  SUM(sr_return_amt) AS total_return_amount,
  AVG(sr_return_quantity) AS avg_return_quantity,
  MIN(p_cost) AS min_promo_cost,
  MAX(p_cost) AS max_promo_cost,
  SUM(CASE WHEN i_current_price > 100 THEN sr_return_amt ELSE 0 END) AS high_price_return_amount
FROM base
GROUP BY
  d_year,
  i_brand,
  i_category,
  region_flag,
  r_reason_desc
ORDER BY total_return_amount DESC
LIMIT 100
