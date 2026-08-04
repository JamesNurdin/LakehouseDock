WITH base AS (
  SELECT
    ss.ss_ticket_number,
    ss.ss_sold_date_sk,
    ss.ss_quantity,
    ss.ss_sales_price,
    ss.ss_net_paid,
    ss.ss_net_profit,
    i.i_item_sk,
    i.i_item_id,
    i.i_current_price,
    i.i_rec_start_date,
    c.c_customer_sk,
    c.c_customer_id,
    c.c_birth_month,
    cd.cd_gender,
    hd.hd_demo_sk,
    hd.hd_income_band_sk,
    ib.ib_upper_bound,
    s.s_store_sk,
    s.s_store_id,
    s.s_state,
    p.p_promo_sk,
    p.p_discount_active
  FROM store_sales ss
  JOIN item i ON ss.ss_item_sk = i.i_item_sk
  JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
)
SELECT DISTINCT
  b.c_customer_id,
  b.i_item_id,
  b.s_store_id,
  b.s_state,
  b.c_birth_month,
  b.i_current_price,
  b.ib_upper_bound,
  b.p_discount_active,
  COALESCE(sr.sr_return_quantity, 0)        AS store_return_qty,
  COALESCE(cr.cr_return_quantity, 0)        AS catalog_return_qty,
  COALESCE(wr.wr_return_quantity, 0)        AS web_return_qty,
  (COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) AS total_net_loss,
  RANK() OVER (PARTITION BY b.s_store_id ORDER BY (COALESCE(sr.sr_net_loss, 0) + COALESCE(cr.cr_net_loss, 0) + COALESCE(wr.wr_net_loss, 0)) DESC) AS loss_rank,
  la.total_catalog_return_amount
FROM base b
FULL OUTER JOIN store_returns sr
  ON b.ss_ticket_number = sr.sr_ticket_number
  AND b.i_item_sk = sr.sr_item_sk
LEFT JOIN reason r
  ON sr.sr_reason_sk = r.r_reason_sk
LEFT JOIN catalog_returns cr
  ON b.i_item_sk = cr.cr_item_sk
LEFT JOIN web_returns wr
  ON b.i_item_sk = wr.wr_item_sk
LEFT JOIN web_page wp
  ON wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN LATERAL (
   SELECT SUM(cr2.cr_return_amount) AS total_catalog_return_amount
   FROM catalog_returns cr2
   WHERE cr2.cr_item_sk = b.i_item_sk
) la ON true
WHERE
  b.c_birth_month IN (3, 4, 5)
  AND b.i_current_price > 50
  AND b.s_state = 'CA'
  AND b.ib_upper_bound >= 100000
  AND b.p_discount_active = 'Y'
  AND r.r_reason_desc LIKE '%defect%'
  AND b.i_rec_start_date >= DATE '2000-01-01'
ORDER BY total_net_loss DESC, loss_rank
LIMIT 100
