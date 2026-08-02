WITH joined_data AS (
  SELECT
    i.i_item_sk,
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    r1.r_reason_desc AS return_reason,
    td_ws.t_hour AS sale_hour,
    ws.ws_ext_sales_price AS sales_amount,
    sr.sr_return_amt AS store_return_amount,
    cr.cr_return_amount AS catalog_return_amount,
    wr.wr_return_amt AS web_return_amount,
    inv.inv_quantity_on_hand,
    ib.ib_lower_bound,
    cc.cc_state,
    cp.cp_catalog_number,
    ws.ws_net_profit,
    wr.wr_account_credit
  FROM item i
  -- inventory (item to inventory)
  JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
  -- store returns chain
  JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
  JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
  JOIN reason r1 ON sr.sr_reason_sk = r1.r_reason_sk
  JOIN customer_demographics cd_sr ON sr.sr_cdemo_sk = cd_sr.cd_demo_sk
  JOIN household_demographics hd_sr ON sr.sr_hdemo_sk = hd_sr.hd_demo_sk
  JOIN income_band ib ON hd_sr.hd_income_band_sk = ib.ib_income_band_sk
  -- catalog returns chain
  JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
  JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
  JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN time_dim td_cr ON cr.cr_returned_time_sk = td_cr.t_time_sk
  JOIN reason r2 ON cr.cr_reason_sk = r2.r_reason_sk
  JOIN customer_demographics cd_cr ON cr.cr_refunded_cdemo_sk = cd_cr.cd_demo_sk
  JOIN household_demographics hd_cr ON cr.cr_refunded_hdemo_sk = hd_cr.hd_demo_sk
  -- web sales chain
  JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
  JOIN time_dim td_ws ON ws.ws_sold_time_sk = td_ws.t_time_sk
  JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN customer_demographics cd_ws_bill ON ws.ws_bill_cdemo_sk = cd_ws_bill.cd_demo_sk
  JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
  -- web returns chain
  JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    AND wr.wr_order_number = ws.ws_order_number
  JOIN time_dim td_wr ON wr.wr_returned_time_sk = td_wr.t_time_sk
  JOIN reason r3 ON wr.wr_reason_sk = r3.r_reason_sk
  JOIN customer_demographics cd_wr_ref ON wr.wr_refunded_cdemo_sk = cd_wr_ref.cd_demo_sk
  JOIN household_demographics hd_wr_ref ON wr.wr_refunded_hdemo_sk = hd_wr_ref.hd_demo_sk
  WHERE
    i.i_current_price > 20
    AND cr.cr_return_amount > 100
    AND inv.inv_quantity_on_hand > 0
    AND ib.ib_lower_bound >= 50000
    AND cc.cc_state = 'CA'
    AND td_ws.t_hour BETWEEN 9 AND 17
    AND wr.wr_item_sk IN (206080, 52886)
),

agg_by_item_reason AS (
  SELECT
    i_item_id,
    i_product_name,
    return_reason,
    SUM(sales_amount) AS total_sales,
    SUM(store_return_amount) AS total_store_returns,
    SUM(catalog_return_amount) AS total_catalog_returns,
    SUM(web_return_amount) AS total_web_returns,
    SUM(ws_net_profit) AS total_net_profit,
    SUM(inv_quantity_on_hand) AS total_inventory,
    SUM(wr_account_credit) AS total_account_credit
  FROM joined_data
  GROUP BY i_item_id, i_product_name, return_reason
),

detail AS (
  SELECT
    i_item_id,
    i_product_name,
    return_reason,
    total_sales,
    total_store_returns,
    total_catalog_returns,
    total_web_returns,
    total_net_profit,
    total_inventory,
    total_account_credit
  FROM agg_by_item_reason
),

summary AS (
  SELECT
    i_item_id,
    i_product_name,
    NULL AS return_reason,
    SUM(total_sales) AS total_sales,
    SUM(total_store_returns) AS total_store_returns,
    SUM(total_catalog_returns) AS total_catalog_returns,
    SUM(total_web_returns) AS total_web_returns,
    SUM(total_net_profit) AS total_net_profit,
    MAX(total_inventory) AS total_inventory,
    SUM(total_account_credit) AS total_account_credit
  FROM agg_by_item_reason
  GROUP BY i_item_id, i_product_name
),

unioned AS (
  SELECT DISTINCT * FROM detail
  UNION
  SELECT * FROM summary
)

SELECT
  i_item_id,
  i_product_name,
  return_reason,
  total_sales,
  total_store_returns,
  total_catalog_returns,
  total_web_returns,
  total_net_profit,
  total_inventory,
  total_account_credit,
  RANK() OVER (ORDER BY total_net_profit DESC) AS profit_rank,
  SUM(total_net_profit) OVER (PARTITION BY i_item_id) AS profit_per_item
FROM unioned
ORDER BY profit_rank
LIMIT 100
