WITH base AS (
  SELECT
    s.s_store_id,
    s.s_state,
    i.i_brand,
    i.i_category,
    r.r_reason_desc,
    cr.cr_return_amount,
    cr.cr_net_loss AS cr_net_loss,
    sr.sr_net_loss AS sr_net_loss,
    ss.ss_net_profit,
    ss.ss_quantity,
    inv.inv_quantity_on_hand,
    td.t_hour,
    cd.cd_purchase_estimate
  FROM time_dim td
  JOIN store_sales ss
    ON ss.ss_sold_time_sk = td.t_time_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN customer_demographics cd
    ON ss.ss_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ss.ss_hdemo_sk = hd.hd_demo_sk
  JOIN store_returns sr
    ON sr.sr_ticket_number = ss.ss_ticket_number
    AND sr.sr_return_time_sk = td.t_time_sk
    AND sr.sr_item_sk = i.i_item_sk
    AND sr.sr_store_sk = s.s_store_sk
  JOIN catalog_returns cr
    ON cr.cr_returned_time_sk = td.t_time_sk
    AND cr.cr_item_sk = i.i_item_sk
  JOIN catalog_page cp
    ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN warehouse w
    ON cr.cr_warehouse_sk = w.w_warehouse_sk
  JOIN reason r
    ON cr.cr_reason_sk = r.r_reason_sk
    AND sr.sr_reason_sk = r.r_reason_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE
    s.s_state = 'CA'
    AND i.i_brand = 'BrandX'
    AND cp.cp_department = 'Sports'
    AND td.t_hour BETWEEN 9 AND 17
    AND inv.inv_quantity_on_hand > 100
    AND cd.cd_purchase_estimate > 5000
)
SELECT
  s_store_id,
  s_state,
  i_brand,
  i_category,
  r_reason_desc,
  SUM(cr_return_amount) AS total_return_amount,
  SUM(cr_net_loss + sr_net_loss) AS total_net_loss,
  SUM(ss_net_profit) AS total_net_profit,
  AVG(ss_quantity) AS avg_quantity_sold,
  COUNT(*) AS transaction_cnt
FROM base
GROUP BY
  s_store_id,
  s_state,
  i_brand,
  i_category,
  r_reason_desc
HAVING SUM(cr_net_loss + sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
