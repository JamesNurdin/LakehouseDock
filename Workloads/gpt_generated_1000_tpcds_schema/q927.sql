/*
  Goal: Identify the most loss‑generating divisions and reasons while showing promotional, geographic and demographic context. The query joins all twelve TPC‑DS tables using only the permitted keys, filters on realistic attribute values, aggregates loss and sales metrics, classifies loss levels with a CASE expression, ranks divisions by loss, and adds a correlated subquery returning the total number of returns for each reason.
*/
WITH joined AS (
  SELECT
    cc.cc_division_name,
    cc.cc_state,
    cp.cp_department,
    sm.sm_type,
    sm.sm_contract,
    w.w_city,
    cd.cd_purchase_estimate,
    r.r_reason_sk,
    r.r_reason_desc,
    cs.cs_sales_price,
    cr.cr_net_loss,
    cr.cr_return_amount,
    sr.sr_return_amt
  FROM tpcds.catalog_sales cs
  LEFT JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  LEFT JOIN tpcds.catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  LEFT JOIN tpcds.ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  LEFT JOIN tpcds.warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  LEFT JOIN tpcds.promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN tpcds.customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
  LEFT JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  FULL OUTER JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
  LEFT JOIN tpcds.reason r
    ON cr.cr_reason_sk = r.r_reason_sk
  LEFT JOIN tpcds.store_returns sr
    ON sr.sr_cdemo_sk = cd.cd_demo_sk
  WHERE cc.cc_state = 'CA'
    AND cp.cp_department = 'Sports'
    AND sm.sm_contract = 'hGoF18SLDDPBj'
    AND w.w_city = 'Mobile'
    AND cd.cd_purchase_estimate BETWEEN 5000 AND 8000
    AND p.p_promo_name LIKE '%Discount%'
    AND cr.cr_return_amount > 1000
    AND sr.sr_return_amt < 500
),
agg AS (
  SELECT
    cc_division_name,
    cp_department,
    sm_type,
    w_city,
    cd_purchase_estimate,
    r_reason_sk,
    r_reason_desc,
    SUM(cr_net_loss) AS total_net_loss,
    AVG(cs_sales_price) AS avg_sales_price,
    COUNT(DISTINCT cs_sales_price) AS distinct_sales_price_cnt,
    SUM(sr_return_amt) AS total_store_return_amt,
    CASE WHEN SUM(cr_net_loss) > 5000 THEN 'HIGH' ELSE 'LOW' END AS loss_category
  FROM joined
  GROUP BY
    cc_division_name,
    cp_department,
    sm_type,
    w_city,
    cd_purchase_estimate,
    r_reason_sk,
    r_reason_desc
)
SELECT
  a.*, 
  (SELECT COUNT(*) FROM tpcds.catalog_returns cr2 WHERE cr2.cr_reason_sk = a.r_reason_sk) AS total_returns_for_reason,
  ROW_NUMBER() OVER (PARTITION BY a.cc_division_name ORDER BY a.total_net_loss DESC) AS division_loss_rank
FROM agg a
ORDER BY a.total_net_loss DESC
LIMIT 100
