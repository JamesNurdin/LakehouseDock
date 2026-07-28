SELECT
    s.s_store_name,
    i.i_product_name,
    p.p_promo_name,
    r.r_reason_desc,
    ss.ss_net_paid,
    sr.sr_net_loss,
    ws.ws_net_paid,
    RANK() OVER (PARTITION BY s.s_store_name ORDER BY ss.ss_net_paid DESC) AS sales_rank,
    SUM(ss.ss_net_paid) OVER (PARTITION BY s.s_store_name) AS total_store_sales,
    CASE WHEN ss.ss_net_paid > 0 THEN 'Positive' ELSE 'Non‑positive' END AS sale_sign,
    (SELECT AVG(ss_inner.ss_ext_discount_amt)
       FROM store_sales ss_inner
      WHERE ss_inner.ss_item_sk = i.i_item_sk) AS avg_item_discount
FROM store_sales ss
JOIN item i
  ON ss.ss_item_sk = i.i_item_sk
JOIN store s
  ON ss.ss_store_sk = s.s_store_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
 AND sr.sr_item_sk = ss.ss_item_sk
 AND sr.sr_store_sk = s.s_store_sk
JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
JOIN web_sales ws
  ON ws.ws_item_sk = i.i_item_sk
 AND ws.ws_promo_sk = p.p_promo_sk
JOIN web_returns wr
  ON wr.wr_order_number = ws.ws_order_number
 AND wr.wr_reason_sk = r.r_reason_sk
WHERE i.i_size IN ('medium', 'large')
  AND p.p_promo_sk BETWEEN 2 AND 10
  AND s.s_state = 'CA'
  AND i.i_rec_start_date > DATE '2000-01-01'
  AND r.r_reason_desc LIKE '%damage%'
ORDER BY sales_rank, s.s_store_name
LIMIT 100
