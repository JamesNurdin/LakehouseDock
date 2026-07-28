WITH
  inv_agg AS (
    SELECT
      inv_item_sk,
      inv_warehouse_sk,
      SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
  ),

  store_metrics AS (
    SELECT
      'store'                                            AS source_type,
      s.s_store_name                                      AS location_name,
      d.d_year                                            AS year,
      i.i_item_id                                         AS item_id,
      SUM(sr.sr_return_amt)                               AS total_amount,
      SUM(sr.sr_return_quantity)                         AS total_quantity,
      COALESCE(inv_agg.total_on_hand, 0)                  AS total_on_hand,
      ib.ib_lower_bound                                   AS income_lower,
      ib.ib_upper_bound                                   AS income_upper,
      cp.cp_catalog_page_id                               AS catalog_page_id,
      cc.cc_name                                          AS call_center_name,
      0                                                   AS total_return_amt_web,
      ROW_NUMBER() OVER (PARTITION BY s.s_store_sk ORDER BY SUM(sr.sr_return_amt) DESC) AS rank_val
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inv_agg ON sr.sr_item_sk = inv_agg.inv_item_sk
    LEFT JOIN promotion p ON i.i_item_sk = p.p_item_sk
    LEFT JOIN catalog_page cp ON d.d_date_sk = cp.cp_start_date_sk
    LEFT JOIN call_center cc ON d.d_date_sk = cc.cc_open_date_sk
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
    GROUP BY
      s.s_store_sk,
      s.s_store_name,
      d.d_year,
      i.i_item_id,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cp.cp_catalog_page_id,
      cc.cc_name,
      inv_agg.total_on_hand
  ),

  web_metrics AS (
    SELECT
      'web'                                              AS source_type,
      wp.wp_url                                           AS location_name,
      d.d_year                                            AS year,
      i.i_item_id                                         AS item_id,
      SUM(ws.ws_ext_sales_price)                          AS total_amount,
      SUM(ws.ws_quantity)                                 AS total_quantity,
      COALESCE(inv_agg.total_on_hand, 0)                  AS total_on_hand,
      ib.ib_lower_bound                                   AS income_lower,
      ib.ib_upper_bound                                   AS income_upper,
      cp.cp_catalog_page_id                               AS catalog_page_id,
      cc.cc_name                                          AS call_center_name,
      COALESCE(SUM(wr.wr_return_amt), 0)                  AS total_return_amt_web,
      ROW_NUMBER() OVER (PARTITION BY wp.wp_web_page_sk ORDER BY SUM(ws.ws_ext_sales_price) DESC) AS rank_val
    FROM web_sales ws
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN inv_agg ON ws.ws_item_sk = inv_agg.inv_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN catalog_page cp ON d.d_date_sk = cp.cp_start_date_sk
    LEFT JOIN call_center cc ON d.d_date_sk = cc.cc_open_date_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    WHERE d.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND wp.wp_type = 'I'
      AND p.p_discount_active = 'Y'
    GROUP BY
      wp.wp_web_page_sk,
      wp.wp_url,
      d.d_year,
      i.i_item_id,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cp.cp_catalog_page_id,
      cc.cc_name,
      inv_agg.total_on_hand
  )

SELECT *
FROM (
  SELECT * FROM store_metrics
  UNION ALL
  SELECT * FROM web_metrics
) final_result
ORDER BY year DESC, total_amount DESC, rank_val
LIMIT 100
