WITH sr_base AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_store_sk,
        sr.sr_reason_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss,
        sr.sr_ticket_number
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 0
)
SELECT
    d_ret.d_year,
    i.i_category,
    r.r_reason_desc,
    SUM(sr.sr_return_amt) AS total_return_amount,
    AVG(sr.sr_return_amt) AS avg_return_amount,
    COUNT(*) AS return_count,
    CASE WHEN SUM(sr.sr_return_amt) > 1000 THEN 'High' ELSE 'Low' END AS return_level
FROM sr_base sr
JOIN date_dim d_ret
  ON sr.sr_returned_date_sk = d_ret.d_date_sk
JOIN time_dim t
  ON sr.sr_return_time_sk = t.t_time_sk
JOIN item i
  ON sr.sr_item_sk = i.i_item_sk
JOIN store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN promotion p
  ON p.p_item_sk = i.i_item_sk
     AND p.p_start_date_sk = d_ret.d_date_sk
     AND p.p_discount_active = 'Y'
LEFT JOIN inventory inv
  ON inv.inv_date_sk = d_ret.d_date_sk
     AND inv.inv_item_sk = i.i_item_sk
     AND inv.inv_quantity_on_hand > 100
JOIN call_center cc
  ON cc.cc_open_date_sk = d_ret.d_date_sk
JOIN web_site ws
  ON ws.web_open_date_sk = d_ret.d_date_sk
JOIN web_page wp
  ON wp.wp_creation_date_sk = d_ret.d_date_sk
WHERE d_ret.d_year = 2001
  AND i.i_category = 'Sports'
  AND s.s_state = 'CA'
  AND d_ret.d_following_holiday = 'N'
GROUP BY GROUPING SETS (
    (d_ret.d_year, i.i_category, r.r_reason_desc),
    (d_ret.d_year, i.i_category),
    (d_ret.d_year),
    ()
)
ORDER BY d_ret.d_year ASC,
         i.i_category ASC NULLS LAST,
         total_return_amount DESC
LIMIT 100
