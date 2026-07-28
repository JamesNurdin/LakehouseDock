WITH inventory_agg AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    cp.cp_department,
    sm.sm_code,
    r_cr.r_reason_desc AS catalog_return_reason,
    r_wr.r_reason_desc AS web_return_reason,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    inv_agg.total_on_hand,
    SUM(ss.ss_ext_sales_price) AS total_sales,
    SUM(cr.cr_return_amount) AS total_catalog_return_amount,
    SUM(wr.wr_return_amt) AS total_web_return_amount,
    SUM(cr.cr_net_loss) + SUM(wr.wr_net_loss) AS total_net_loss,
    CASE WHEN SUM(ss.ss_ext_sales_price) > 100000 THEN 'High' ELSE 'Normal' END AS sales_category,
    ROW_NUMBER() OVER (PARTITION BY i.i_item_id ORDER BY SUM(ss.ss_ext_sales_price) DESC) AS sales_rank
FROM inventory_agg inv_agg
JOIN item i
  ON i.i_item_sk = inv_agg.inv_item_sk
JOIN store_sales ss
  ON ss.ss_item_sk = i.i_item_sk
JOIN time_dim td_sales
  ON ss.ss_sold_time_sk = td_sales.t_time_sk
JOIN promotion p
  ON ss.ss_promo_sk = p.p_promo_sk
JOIN household_demographics hd_sales
  ON ss.ss_hdemo_sk = hd_sales.hd_demo_sk
JOIN income_band ib
  ON hd_sales.hd_income_band_sk = ib.ib_income_band_sk
JOIN customer_address ca_sales
  ON ss.ss_addr_sk = ca_sales.ca_address_sk
JOIN catalog_returns cr
  ON cr.cr_item_sk = i.i_item_sk
 AND cr.cr_returned_time_sk = td_sales.t_time_sk
JOIN time_dim td_cat
  ON cr.cr_returned_time_sk = td_cat.t_time_sk
JOIN catalog_page cp
  ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN reason r_cr
  ON cr.cr_reason_sk = r_cr.r_reason_sk
JOIN web_returns wr
  ON wr.wr_item_sk = i.i_item_sk
 AND wr.wr_returned_time_sk = td_sales.t_time_sk
JOIN time_dim td_web
  ON wr.wr_returned_time_sk = td_web.t_time_sk
JOIN reason r_wr
  ON wr.wr_reason_sk = r_wr.r_reason_sk
WHERE
    i.i_current_price BETWEEN 10 AND 100
  AND td_sales.t_hour BETWEEN 9 AND 17
  AND inv_agg.total_on_hand > 500
  AND ib.ib_lower_bound >= 70001
  AND sm.sm_code = 'AIR'
  AND cp.cp_department = 'Electronics'
  AND NOT EXISTS (
        SELECT 1
        FROM catalog_returns cr_not
        WHERE cr_not.cr_item_sk = i.i_item_sk
          AND cr_not.cr_returned_date_sk = ss.ss_sold_date_sk
          AND cr_not.cr_return_amount > 0
    )
GROUP BY
    i.i_item_id,
    i.i_product_name,
    i.i_current_price,
    cp.cp_department,
    sm.sm_code,
    r_cr.r_reason_desc,
    r_wr.r_reason_desc,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    inv_agg.total_on_hand
ORDER BY total_sales DESC, i.i_item_id
LIMIT 100
