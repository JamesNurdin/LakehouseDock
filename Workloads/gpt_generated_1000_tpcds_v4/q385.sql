WITH item_price_avg AS (
    SELECT i_brand, AVG(i_current_price) AS avg_price
    FROM tpcds.item
    GROUP BY i_brand
)
SELECT
    s.s_store_name,
    s.s_state,
    r1.r_reason_desc AS store_return_reason,
    r2.r_reason_desc AS catalog_return_reason,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    SUM(sr.sr_return_amt) AS total_store_return_amount,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss) AS total_net_loss,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_count,
    COUNT(DISTINCT cr.cr_order_number) AS catalog_return_count,
    AVG(i1.i_current_price) AS avg_item_price_in_returns,
    AVG(ip.avg_price) OVER (PARTITION BY s.s_state) AS state_avg_brand_price,
    ROW_NUMBER() OVER (ORDER BY (SUM(sr.sr_net_loss) + SUM(cr.cr_net_loss)) DESC) AS loss_rank
FROM tpcds.store_returns sr
JOIN tpcds.item i1
  ON sr.sr_item_sk = i1.i_item_sk
JOIN tpcds.customer c1
  ON sr.sr_customer_sk = c1.c_customer_sk
JOIN tpcds.household_demographics hd1
  ON sr.sr_hdemo_sk = hd1.hd_demo_sk
JOIN tpcds.store s
  ON sr.sr_store_sk = s.s_store_sk
JOIN tpcds.reason r1
  ON sr.sr_reason_sk = r1.r_reason_sk
JOIN tpcds.catalog_returns cr
  ON cr.cr_item_sk = i1.i_item_sk
JOIN tpcds.item i2
  ON cr.cr_item_sk = i2.i_item_sk
JOIN tpcds.customer c_refund
  ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
JOIN tpcds.customer c_returning
  ON cr.cr_returning_customer_sk = c_returning.c_customer_sk
JOIN tpcds.household_demographics hd_refund
  ON cr.cr_refunded_hdemo_sk = hd_refund.hd_demo_sk
JOIN tpcds.household_demographics hd_returning
  ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN tpcds.call_center cc
  ON cr.cr_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.warehouse w
  ON cr.cr_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.reason r2
  ON cr.cr_reason_sk = r2.r_reason_sk
JOIN tpcds.income_band ib
  ON hd1.hd_income_band_sk = ib.ib_income_band_sk
JOIN item_price_avg ip
  ON i1.i_brand = ip.i_brand
WHERE EXISTS (
    SELECT 1
    FROM tpcds.store_returns sr2
    WHERE sr2.sr_store_sk = s.s_store_sk
      AND sr2.sr_net_loss > 1000
)
  AND s.s_division_id = 1
GROUP BY
    s.s_store_name,
    s.s_state,
    r1.r_reason_desc,
    r2.r_reason_desc,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    ip.i_brand,
    ip.avg_price
ORDER BY total_net_loss DESC
