WITH base AS (
  SELECT
    cp.cp_catalog_page_sk,
    cp.cp_department,
    cp.cp_catalog_number,
    cs.cs_order_number,
    cs.cs_quantity,
    cs.cs_sales_price,
    cs.cs_ext_discount_amt,
    cs.cs_net_profit,
    p.p_promo_id,
    p.p_discount_active,
    ca.ca_state,
    hd.hd_income_band_sk,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cr.cr_return_amount,
    sr.sr_return_ship_cost,
    ws.ws_net_paid_inc_ship_tax,
    ws.ws_quantity
  FROM catalog_page cp
  JOIN catalog_sales cs
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN promotion p
    ON cs.cs_promo_sk = p.p_promo_sk
  JOIN catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
  JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
  JOIN household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
  JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
  JOIN store_returns sr
    ON sr.sr_addr_sk = ca.ca_address_sk
   AND sr.sr_hdemo_sk = hd.hd_demo_sk
  JOIN web_sales ws
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   AND ws.ws_promo_sk = p.p_promo_sk
  JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
  WHERE
    cp.cp_catalog_number IN (16, 20)
    AND cp.cp_start_date_sk BETWEEN 2450845 AND 2451145
    AND cs.cs_quantity > 5
    AND cs.cs_sales_price > 100
    AND p.p_discount_active = 'Y'
    AND ib.ib_lower_bound >= 50000
    AND cr.cr_return_amount > 50
    AND sr.sr_return_ship_cost < 200
    AND ws.ws_net_paid_inc_ship_tax > 500
),
agg AS (
  SELECT
    cp_department,
    cp_catalog_number,
    COUNT(DISTINCT cs_order_number) AS num_orders,
    SUM(cs_sales_price * cs_quantity) AS total_sales_amount,
    SUM(cr_return_amount) AS total_return_amount,
    AVG(cs_ext_discount_amt) AS avg_discount,
    MIN(ws_net_paid_inc_ship_tax) AS min_net_paid_inc_ship_tax,
    MAX(cs_net_profit) AS max_net_profit
  FROM base
  GROUP BY cp_department, cp_catalog_number
)
SELECT
  cp_department,
  cp_catalog_number,
  num_orders,
  total_sales_amount,
  total_return_amount,
  avg_discount,
  min_net_paid_inc_ship_tax,
  max_net_profit,
  ROW_NUMBER() OVER (PARTITION BY cp_department ORDER BY total_sales_amount DESC) AS dept_sales_rank
FROM agg
ORDER BY total_sales_amount DESC
LIMIT 100
