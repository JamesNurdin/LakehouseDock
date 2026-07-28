WITH inv_agg AS (
        SELECT inv_item_sk,
               SUM(inv_quantity_on_hand) AS total_on_hand
        FROM inventory
        GROUP BY inv_item_sk
    ),
    store_sales_agg AS (
        SELECT ss_item_sk,
               ss_store_sk,
               SUM(ss_ext_sales_price) AS store_sales_total,
               SUM(ss_quantity) AS store_qty
        FROM store_sales
        GROUP BY ss_item_sk, ss_store_sk
    ),
    web_sales_agg AS (
        SELECT ws_item_sk,
               ws_web_site_sk,
               ws_web_page_sk,
               SUM(ws_ext_sales_price) AS web_sales_total
        FROM web_sales
        GROUP BY ws_item_sk, ws_web_site_sk, ws_web_page_sk
    )
SELECT
    cr.cr_order_number,
    i.i_item_id,
    c.c_customer_id,
    ca.ca_city,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    sm.sm_type,
    r.r_reason_desc,
    td.t_hour,
    ss_agg.store_sales_total,
    ws_agg.web_sales_total,
    inv_agg.total_on_hand,
    (SELECT AVG(total_on_hand) FROM inv_agg) AS avg_on_hand,
    (cr.cr_return_amount + cr.cr_return_tax) AS total_return_amount
FROM catalog_returns cr
JOIN time_dim td
  ON cr.cr_returned_time_sk = td.t_time_sk
JOIN item i
  ON cr.cr_item_sk = i.i_item_sk
JOIN customer c
  ON cr.cr_refunded_customer_sk = c.c_customer_sk
JOIN customer_address ca
  ON cr.cr_refunded_addr_sk = ca.ca_address_sk
JOIN household_demographics hd
  ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
JOIN income_band ib
  ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN reason r
  ON cr.cr_reason_sk = r.r_reason_sk
JOIN ship_mode sm
  ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
JOIN store_sales_agg ss_agg
  ON ss_agg.ss_item_sk = i.i_item_sk
JOIN store s
  ON ss_agg.ss_store_sk = s.s_store_sk
JOIN inv_agg
  ON inv_agg.inv_item_sk = i.i_item_sk
JOIN web_sales_agg ws_agg
  ON ws_agg.ws_item_sk = i.i_item_sk
JOIN web_site ws
  ON ws_agg.ws_web_site_sk = ws.web_site_sk
JOIN web_page wp
  ON ws_agg.ws_web_page_sk = wp.wp_web_page_sk
WHERE td.t_hour BETWEEN 8 AND 18
  AND i.i_current_price > 20.00
  AND c.c_preferred_cust_flag = 'Y'
  AND ib.ib_lower_bound >= 50000
  AND sm.sm_type = 'AIR'
  AND s.s_state = 'CA'
  AND (cr.cr_return_amount + cr.cr_return_tax) > 0
ORDER BY total_return_amount DESC
LIMIT 100
