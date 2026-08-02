WITH
  catalog_agg AS (
    SELECT
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      cr.cr_warehouse_sk,
      cr.cr_call_center_sk,
      cr.cr_catalog_page_sk,
      cr.cr_reason_sk,
      cr.cr_refunded_hdemo_sk,
      SUM(cr.cr_return_amount) AS sum_return_amount,
      SUM(cr.cr_net_loss) AS sum_net_loss,
      COUNT(*) AS cnt_returns
    FROM catalog_returns cr
    GROUP BY
      cr.cr_item_sk,
      cr.cr_returned_date_sk,
      cr.cr_warehouse_sk,
      cr.cr_call_center_sk,
      cr.cr_catalog_page_sk,
      cr.cr_reason_sk,
      cr.cr_refunded_hdemo_sk
  ),
  store_agg AS (
    SELECT
      sr.sr_item_sk,
      sr.sr_returned_date_sk,
      sr.sr_reason_sk,
      sr.sr_hdemo_sk,
      sr.sr_customer_sk,
      sr.sr_cdemo_sk,
      SUM(sr.sr_return_amt) AS sum_return_amt,
      SUM(sr.sr_net_loss) AS sum_net_loss,
      COUNT(*) AS cnt_store_returns
    FROM store_returns sr
    GROUP BY
      sr.sr_item_sk,
      sr.sr_returned_date_sk,
      sr.sr_reason_sk,
      sr.sr_hdemo_sk,
      sr.sr_customer_sk,
      sr.sr_cdemo_sk
  ),
  distinct_items_in_cat_not_store AS (
    SELECT DISTINCT cr_item_sk AS item_sk FROM catalog_returns
    EXCEPT
    SELECT DISTINCT sr_item_sk AS item_sk FROM store_returns
  ),
  all_items AS (
    SELECT cr_item_sk AS item_sk FROM catalog_returns
    UNION
    SELECT sr_item_sk AS item_sk FROM store_returns
  ),
  combined_returns AS (
    SELECT
      ca.cr_item_sk AS item_sk,
      ca.cr_returned_date_sk AS date_sk,
      ca.cr_warehouse_sk AS warehouse_sk,
      ca.cr_call_center_sk AS call_center_sk,
      ca.cr_catalog_page_sk AS catalog_page_sk,
      ca.cr_reason_sk AS reason_sk,
      ca.cr_refunded_hdemo_sk AS hdemo_sk,
      ca.sum_return_amount AS catalog_return_amount,
      ca.sum_net_loss AS catalog_net_loss,
      ca.cnt_returns AS catalog_cnt,
      COALESCE(sa.sum_return_amt, 0) AS store_return_amount,
      COALESCE(sa.sum_net_loss, 0) AS store_net_loss,
      COALESCE(sa.cnt_store_returns, 0) AS store_cnt,
      sa.sr_customer_sk AS customer_sk,
      sa.sr_cdemo_sk AS cdemo_sk
    FROM catalog_agg ca
    LEFT JOIN store_agg sa
      ON ca.cr_item_sk = sa.sr_item_sk
     AND ca.cr_returned_date_sk = sa.sr_returned_date_sk
     AND ca.cr_reason_sk = sa.sr_reason_sk
     AND ca.cr_refunded_hdemo_sk = sa.sr_hdemo_sk
    WHERE ca.cr_item_sk IN (SELECT item_sk FROM distinct_items_in_cat_not_store)
      AND ca.cr_item_sk IN (SELECT item_sk FROM all_items)
  )
SELECT DISTINCT
  d.d_year,
  i.i_item_id,
  i.i_product_name,
  w.w_warehouse_name,
  cc.cc_name AS call_center_name,
  cp.cp_catalog_number,
  r.r_reason_desc,
  (combined_returns.catalog_return_amount + combined_returns.store_return_amount) AS total_return_amount,
  (combined_returns.catalog_net_loss + combined_returns.store_net_loss) AS total_net_loss,
  CASE
    WHEN (combined_returns.catalog_net_loss + combined_returns.store_net_loss) > 1000 THEN 'High'
    ELSE 'Low'
  END AS loss_category,
  DENSE_RANK() OVER (PARTITION BY d.d_year ORDER BY (combined_returns.catalog_net_loss + combined_returns.store_net_loss) DESC) AS yearly_loss_rank,
  ib.ib_upper_bound,
  cd.cd_gender,
  hd.hd_buy_potential,
  c.c_customer_id
FROM combined_returns
JOIN date_dim d ON combined_returns.date_sk = d.d_date_sk
JOIN item i ON combined_returns.item_sk = i.i_item_sk
JOIN warehouse w ON combined_returns.warehouse_sk = w.w_warehouse_sk
JOIN call_center cc ON combined_returns.call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON combined_returns.catalog_page_sk = cp.cp_catalog_page_sk
JOIN reason r ON combined_returns.reason_sk = r.r_reason_sk
JOIN household_demographics hd ON combined_returns.hdemo_sk = hd.hd_demo_sk
JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN customer c ON combined_returns.customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd ON combined_returns.cdemo_sk = cd.cd_demo_sk
WHERE d.d_year = 2000
  AND i.i_current_price > 20
  AND cc.cc_state = 'CA'
  AND w.w_state = 'TX'
  AND r.r_reason_desc LIKE '%defective%'
ORDER BY yearly_loss_rank ASC, d.d_year ASC, total_net_loss DESC
LIMIT 100
