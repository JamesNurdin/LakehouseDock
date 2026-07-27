WITH filtered_returns AS (
    SELECT *
    FROM catalog_returns
    WHERE cr_return_quantity > 0
      AND cr_return_amount > 100
)
SELECT
    d.d_year,
    i.i_brand,
    w.w_city,
    s.s_state,
    cc.cc_name,
    SUM(cr.cr_return_amount) AS total_return_amount,
    COUNT(*) AS return_cnt,
    AVG(cr.cr_return_quantity) AS avg_quantity,
    MIN(cr.cr_return_amount) AS min_return,
    MAX(cr.cr_return_amount) AS max_return
FROM filtered_returns cr
JOIN date_dim d
  ON cr.cr_returned_date_sk = d.d_date_sk
JOIN time_dim t
  ON cr.cr_returned_time_sk = t.t_time_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN customer_address ca_refund
  ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
JOIN customer_address ca_return
  ON cr.cr_returning_addr_sk = ca_return.ca_address_sk
JOIN promotion p
  ON i.i_item_sk = p.p_item_sk
JOIN date_dim d_promo
  ON p.p_start_date_sk = d_promo.d_date_sk
JOIN store s
  ON s.s_closed_date_sk = d.d_date_sk
WHERE
    d.d_year = 2001
    AND d.d_quarter_seq = 12
    AND w.w_street_name = 'Wilson Elm'
    AND p.p_channel_catalog = 'N'
    AND cc.cc_state = 'TX'
    AND t.t_hour BETWEEN 9 AND 17
GROUP BY GROUPING SETS (
    (d.d_year, i.i_brand, w.w_city, s.s_state, cc.cc_name),
    (d.d_year, i.i_brand, w.w_city, s.s_state),
    (d.d_year, i.i_brand, w.w_city),
    (d.d_year, i.i_brand),
    (d.d_year),
    ()
)
ORDER BY total_return_amount DESC
LIMIT 100
