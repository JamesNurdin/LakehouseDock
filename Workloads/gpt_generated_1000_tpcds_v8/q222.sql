SELECT
    s.s_store_id,
    s.s_state,
    d.d_date,
    t.t_hour,
    hd.hd_income_band_sk,
    p.p_promo_name,
    ss.ss_ticket_number,
    ss.ss_net_paid,
    cr.cr_return_amount,
    r_cat.r_reason_desc AS cr_reason_desc,
    wr.wr_return_amt,
    r_web.r_reason_desc AS wr_reason_desc,
    inv.inv_quantity_on_hand,
    (
        SELECT COUNT(*)
        FROM web_returns wr2
        WHERE wr2.wr_returned_date_sk = d.d_date_sk
          AND wr2.wr_item_sk = ss.ss_item_sk
    ) AS web_return_cnt_for_item,
    ROW_NUMBER() OVER (PARTITION BY s.s_state ORDER BY ss.ss_net_paid DESC) AS state_row_num,
    DENSE_RANK() OVER (ORDER BY ss.ss_net_paid DESC) AS global_sales_rank
FROM store_sales ss
JOIN date_dim d
  ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
  ON ss.ss_sold_time_sk = t.t_time_sk
JOIN household_demographics hd
  ON ss.ss_hdemo_sk = hd.hd_demo_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
LEFT JOIN catalog_returns cr
  ON cr.cr_returned_date_sk = d.d_date_sk
 AND cr.cr_returned_time_sk = t.t_time_sk
 AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN reason r_cat
  ON cr.cr_reason_sk = r_cat.r_reason_sk
LEFT JOIN web_returns wr
  ON wr.wr_returned_date_sk = d.d_date_sk
 AND wr.wr_returned_time_sk = t.t_time_sk
 AND wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
LEFT JOIN reason r_web
  ON wr.wr_reason_sk = r_web.r_reason_sk
LEFT JOIN inventory inv
  ON inv.inv_date_sk = d.d_date_sk
WHERE
    s.s_state = 'CA'
    AND d.d_year = 2000
    AND inv.inv_quantity_on_hand > 500
    AND r_cat.r_reason_desc LIKE '%price%'
    AND ss.ss_item_sk IN (SELECT inv_item_sk FROM inventory WHERE inv_quantity_on_hand > 600)
    AND EXISTS (
        SELECT 1
        FROM web_returns wr3
        WHERE wr3.wr_order_number = cr.cr_order_number
          AND wr3.wr_returned_date_sk = d.d_date_sk
    )
ORDER BY s.s_store_id, state_row_num
LIMIT 100
