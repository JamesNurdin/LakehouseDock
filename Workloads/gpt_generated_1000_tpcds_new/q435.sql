WITH sales_union AS (
  -- First branch: catalog sales and related dimensions
  SELECT
    cs.cs_order_number                         AS order_number,
    cs.cs_sold_date_sk,
    cs.cs_sold_time_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    c_bill.c_customer_id,
    cd_bill.cd_gender,
    hd_bill.hd_buy_potential,
    w.w_warehouse_name,
    p.p_promo_name,
    sm.sm_carrier,
    CASE WHEN sm.sm_carrier = 'USPS' THEN cs.cs_net_profit ELSE 0 END AS usps_profit,
    inv_latest.inv_quantity_on_hand,
    r_cr.r_reason_desc,
    d_sold.d_year
  FROM catalog_sales cs
  JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
  JOIN time_dim t_sold ON cs.cs_sold_time_sk = t_sold.t_time_sk
  JOIN customer c_bill ON cs.cs_bill_customer_sk = c_bill.c_customer_sk
  JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
  LEFT JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
  LEFT JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
  LEFT JOIN LATERAL (
        SELECT inv.inv_quantity_on_hand
        FROM inventory inv
        WHERE inv.inv_item_sk = cs.cs_item_sk
          AND inv.inv_warehouse_sk = w.w_warehouse_sk
          AND inv.inv_date_sk = cs.cs_sold_date_sk
        ORDER BY inv.inv_date_sk DESC
        LIMIT 1
  ) inv_latest ON TRUE
  LEFT JOIN web_page wp
    ON wp.wp_customer_sk = c_bill.c_customer_sk
   AND wp.wp_creation_date_sk = d_sold.d_date_sk
  WHERE d_sold.d_year = 2001
    AND hd_bill.hd_buy_potential = '501-1000'
    AND cd_bill.cd_gender = 'M'
    AND sm.sm_carrier IN ('USPS', 'MSC')
    AND p.p_discount_active = 'Y'
    AND w.w_state = 'CA'
    AND (cr.cr_return_amount IS NULL OR cr.cr_return_amount > 100)

  UNION DISTINCT

  -- Second branch: store returns and related dimensions
  SELECT
    sr.sr_ticket_number                      AS order_number,
    sr.sr_returned_date_sk,
    sr.sr_return_time_sk,
    sr.sr_return_quantity,
    sr.sr_return_amt,
    sr.sr_net_loss * -1,
    c.c_customer_id,
    cd.cd_gender,
    hd.hd_buy_potential,
    NULL AS w_warehouse_name,
    NULL AS p_promo_name,
    NULL AS sm_carrier,
    CASE WHEN NULL = 'USPS' THEN sr.sr_net_loss * -1 ELSE 0 END AS usps_profit,
    NULL AS inv_quantity_on_hand,
    r_sr.r_reason_desc,
    d.d_year
  FROM store_returns sr
  JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
  JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
  JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
  JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
  WHERE d.d_year = 2001
),
aggregated AS (
  SELECT
    order_number,
    c_customer_id,
    w_warehouse_name,
    d_year,
    SUM(cs_quantity)               AS total_quantity,
    AVG(cs_net_paid)               AS avg_net_paid,
    SUM(usps_profit)               AS total_usps_profit,
    COUNT(*)                       AS txn_count
  FROM sales_union
  GROUP BY GROUPING SETS (
    (order_number, c_customer_id, w_warehouse_name, d_year),
    (c_customer_id, d_year),
    (w_warehouse_name, d_year)
  )
)
SELECT
  order_number,
  c_customer_id,
  w_warehouse_name,
  d_year,
  total_quantity,
  avg_net_paid,
  total_usps_profit,
  txn_count,
  ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_quantity DESC) AS rn
FROM aggregated
ORDER BY d_year, total_quantity DESC
