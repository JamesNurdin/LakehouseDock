WITH
  base AS (
    SELECT
      d.d_year,
      d.d_month_seq,
      i.i_item_id,
      i.i_category,
      i.i_brand,
      i.i_current_price,
      c.c_customer_id,
      ca.ca_state,
      hd.hd_income_band_sk,
      cc.cc_name,
      cp.cp_department,
      sm.sm_type AS ship_type,
      w.w_state,
      p.p_discount_active,
      cs.cs_ext_sales_price AS catalog_sales_amount,
      ws.ws_ext_sales_price AS web_sales_amount,
      sr.sr_return_amt AS store_return_amount,
      cr.cr_return_amount AS catalog_return_amount,
      wr.wr_return_amt AS web_return_amount
    FROM date_dim d
    JOIN catalog_sales cs               ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN web_sales ws                   ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN store_returns sr               ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN catalog_returns cr             ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN web_returns wr                ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i                         ON cs.cs_item_sk = i.i_item_sk
                                         AND ws.ws_item_sk = i.i_item_sk
                                         AND sr.sr_item_sk = i.i_item_sk
                                         AND cr.cr_item_sk = i.i_item_sk
    JOIN customer c                     ON cs.cs_bill_customer_sk = c.c_customer_sk
                                         AND ws.ws_bill_customer_sk = c.c_customer_sk
                                         AND sr.sr_customer_sk = c.c_customer_sk
                                         AND cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_address ca            ON cs.cs_bill_addr_sk = ca.ca_address_sk
                                         AND ws.ws_bill_addr_sk = ca.ca_address_sk
                                         AND sr.sr_addr_sk = ca.ca_address_sk
                                         AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd       ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
                                         AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
                                         AND sr.sr_hdemo_sk = hd.hd_demo_sk
                                         AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN call_center cc                 ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp                ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm                   ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w                    ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p                    ON cs.cs_promo_sk = p.p_promo_sk
    JOIN web_page wp                    ON ws.ws_web_page_sk = wp.wp_web_page_sk
                                         AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE
      wr.wr_order_number = ws.ws_order_number
      AND cr.cr_order_number = cs.cs_order_number
  ),
  aggregated AS (
    SELECT
      d_year,
      i_category,
      cc_name,
      SUM(catalog_sales_amount) AS total_catalog_sales,
      SUM(web_sales_amount) AS total_web_sales,
      SUM(store_return_amount) AS total_store_returns,
      SUM(catalog_return_amount) AS total_catalog_returns,
      SUM(web_return_amount) AS total_web_returns,
      SUM(catalog_sales_amount - store_return_amount - catalog_return_amount) AS net_sales,
      CASE
        WHEN SUM(catalog_sales_amount) > 100000 THEN 'HIGH'
        ELSE 'NORMAL'
      END AS sales_volume_category
    FROM base
    WHERE
      d_year BETWEEN 2000 AND 2002
      AND i_current_price > 20
      AND ca_state = 'CA'
      AND ship_type = 'AIR'
      AND w_state = 'CA'
      AND p_discount_active = 'Y'
    GROUP BY ROLLUP (d_year, i_category, cc_name)
    HAVING SUM(catalog_sales_amount) > 50000
  ),
  ranked AS (
    SELECT
      d_year,
      i_category,
      cc_name,
      total_catalog_sales,
      total_web_sales,
      total_store_returns,
      total_catalog_returns,
      total_web_returns,
      net_sales,
      sales_volume_category,
      ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY net_sales DESC) AS rank_in_year
    FROM aggregated
  )
SELECT
  d_year,
  i_category,
  cc_name,
  total_catalog_sales,
  total_web_sales,
  total_store_returns,
  total_catalog_returns,
  total_web_returns,
  net_sales,
  sales_volume_category,
  rank_in_year
FROM ranked
WHERE rank_in_year <= 10
ORDER BY d_year, rank_in_year
LIMIT 100
