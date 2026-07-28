WITH sales_data AS (
  SELECT
    s.s_store_id,
    i.i_item_id,
    ss.ss_sold_date_sk,
    ss.ss_quantity,
    ss.ss_ext_sales_price,
    CASE WHEN ss.ss_quantity > 5 THEN 'Bulk' ELSE 'Regular' END AS qty_category,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY ss.ss_ext_sales_price DESC) AS sales_rank,
    cr.cr_return_amount,
    CASE WHEN cr.cr_return_amount > 0 THEN 'Return' ELSE 'Sale' END AS transaction_type,
    ib.ib_lower_bound,
    ib.ib_upper_bound
  FROM catalog_returns cr
  JOIN item i
    ON cr.cr_item_sk = i.i_item_sk
  JOIN time_dim td_ret
    ON cr.cr_returned_time_sk = td_ret.t_time_sk
  JOIN customer_demographics cd_ref
    ON cr.cr_refunded_cdemo_sk = cd_ref.cd_demo_sk
  JOIN household_demographics hd_ref
    ON cr.cr_refunded_hdemo_sk = hd_ref.hd_demo_sk
  JOIN income_band ib
    ON hd_ref.hd_income_band_sk = ib.ib_income_band_sk
  JOIN customer_address ca_ref
    ON cr.cr_refunded_addr_sk = ca_ref.ca_address_sk
  JOIN ship_mode sm
    ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
  JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
  JOIN time_dim td_sales
    ON ss.ss_sold_time_sk = td_sales.t_time_sk
  JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
  JOIN inventory inv
    ON inv.inv_item_sk = i.i_item_sk
  JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
   AND ws.ws_sold_time_sk = td_sales.t_time_sk
  JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
  JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  WHERE s.s_state = 'TX'
    AND i.i_current_price > 20
    AND td_sales.t_hour BETWEEN 9 AND 17
    AND cr.cr_return_amount > 0
    AND EXISTS (
        SELECT 1 FROM call_center cc
        WHERE cc.cc_call_center_sk = cr.cr_call_center_sk
          AND cc.cc_country = 'USA'
    )
)
SELECT *
FROM sales_data
ORDER BY s_store_id, sales_rank
LIMIT 100
