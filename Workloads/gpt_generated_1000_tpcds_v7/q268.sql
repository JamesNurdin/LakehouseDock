WITH filtered_returns AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_item_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt_inc_tax,
        sr.sr_ticket_number
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 20
      AND sr.sr_return_amt_inc_tax > 100.00
)
SELECT
    w.w_city AS warehouse_city,
    i.i_category AS item_category,
    d_ret.d_year,
    COUNT(DISTINCT fr.sr_ticket_number) AS num_returns,
    SUM(fr.sr_return_amt_inc_tax) AS total_return_amount,
    AVG(i.i_current_price) AS avg_item_price,
    MIN(inv.inv_quantity_on_hand) AS min_qty_on_hand,
    COUNT(DISTINCT p.p_promo_id) AS promo_count
FROM filtered_returns fr
JOIN date_dim d_ret
    ON fr.sr_returned_date_sk = d_ret.d_date_sk
JOIN item i
    ON fr.sr_item_sk = i.i_item_sk
JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d_ret.d_date_sk
JOIN warehouse w
    ON inv.inv_warehouse_sk = w.w_warehouse_sk
LEFT JOIN promotion p
    ON p.p_item_sk = i.i_item_sk
   AND p.p_start_date_sk <= d_ret.d_date_sk
   AND p.p_end_date_sk >= d_ret.d_date_sk
   AND p.p_channel_dmail = 'Y'
LEFT JOIN call_center cc
    ON cc.cc_closed_date_sk = d_ret.d_date_sk
   AND cc.cc_state = 'CA'
WHERE d_ret.d_year = 2001
  AND i.i_manufact_id IN (260, 214)
GROUP BY w.w_city, i.i_category, d_ret.d_year
HAVING SUM(fr.sr_return_amt_inc_tax) > (
    SELECT AVG(sr_return_amt_inc_tax) * 1.2
    FROM store_returns
)
ORDER BY total_return_amount DESC
LIMIT 10
