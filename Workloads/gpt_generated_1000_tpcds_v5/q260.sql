WITH base_data AS (
  SELECT
    cr.cr_net_loss AS cr_net_loss,
    sr.sr_net_loss AS sr_net_loss,
    cs.cs_ext_sales_price,
    cs.cs_quantity,
    r_cr.r_reason_desc,
    ib.ib_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    hd_refunded.hd_dep_count,
    ca_refunded.ca_state
  FROM catalog_returns cr
  JOIN catalog_sales cs
    ON cr.cr_item_sk = cs.cs_item_sk
   AND cr.cr_order_number = cs.cs_order_number
  JOIN reason r_cr
    ON cr.cr_reason_sk = r_cr.r_reason_sk
  JOIN customer_address ca_refunded
    ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
  JOIN household_demographics hd_refunded
    ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
  JOIN income_band ib
    ON hd_refunded.hd_income_band_sk = ib.ib_income_band_sk
  JOIN store_returns sr
    ON sr.sr_addr_sk = ca_refunded.ca_address_sk
  JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
  JOIN customer_demographics cd_bill
    ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
  JOIN household_demographics hd_bill
    ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN customer_address ca_bill
    ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
  WHERE cr.cr_warehouse_sk IN (4, 14, 20)
    AND cr.cr_reason_sk = 52
    AND cs.cs_quantity > 1
    AND hd_refunded.hd_dep_count >= 2
    AND ib.ib_lower_bound >= 50000
    AND ca_refunded.ca_state = 'CA'
)
SELECT
  r_reason_desc,
  ib_income_band_sk,
  COUNT(*) AS return_cnt,
  SUM(cr_net_loss + sr_net_loss) AS total_net_loss,
  AVG(cs_ext_sales_price) AS avg_sales_price,
  SUM(cs_quantity) AS total_quantity
FROM base_data
GROUP BY r_reason_desc, ib_income_band_sk
HAVING SUM(cr_net_loss + sr_net_loss) > 1000
ORDER BY total_net_loss DESC
LIMIT 100
