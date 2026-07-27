WITH filtered_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_item_sk,
        sr.sr_cdemo_sk,
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_return_amt_inc_tax,
        sr.sr_ticket_number
    FROM store_returns sr
    WHERE sr.sr_returned_date_sk BETWEEN 2451500 AND 2452000
      AND sr.sr_return_quantity > 0
)
SELECT
    s.s_store_name,
    s.s_state,
    i.i_category,
    cd.cd_gender,
    p.p_promo_name,
    COUNT(DISTINCT fr.sr_ticket_number) AS cnt_tickets,
    SUM(fr.sr_return_amt) AS total_return_amount,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(fr.sr_returned_date_sk) AS min_return_date_sk,
    MAX(fr.sr_returned_date_sk) AS max_return_date_sk
FROM filtered_returns fr
JOIN store s
  ON fr.sr_store_sk = s.s_store_sk
JOIN item i
  ON fr.sr_item_sk = i.i_item_sk
JOIN customer_demographics cd
  ON fr.sr_cdemo_sk = cd.cd_demo_sk
JOIN promotion p
  ON i.i_item_sk = p.p_item_sk
WHERE s.s_rec_start_date >= DATE '2000-01-01'
  AND s.s_rec_start_date < DATE '2002-01-01'
  AND s.s_geography_class = 'Unknown'
  AND s.s_state = 'CA'
  AND cd.cd_credit_rating = 'Low Risk'
  AND cd.cd_dep_count BETWEEN 1 AND 3
  AND i.i_current_price > 20.00
  AND p.p_discount_active = 'Y'
GROUP BY
    s.s_store_name,
    s.s_state,
    i.i_category,
    cd.cd_gender,
    p.p_promo_name
ORDER BY total_return_amount DESC
LIMIT 100
