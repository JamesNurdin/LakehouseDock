WITH
  item_common AS (
    SELECT ws.ws_item_sk
    FROM tpcds.web_sales ws
    WHERE ws.ws_quantity > 5
    INTERSECT
    SELECT cr.cr_item_sk
    FROM tpcds.catalog_returns cr
    WHERE cr.cr_return_quantity > 0
  ),
  base AS (
    SELECT
      ws.ws_order_number,
      ws.ws_sold_date_sk,
      d_sold.d_date      AS sold_date,
      d_sold.d_year,
      i.i_item_sk,
      i.i_product_name,
      i.i_current_price,
      i.i_brand_id,
      i.i_brand,
      c.c_customer_sk,
      c.c_first_name,
      c.c_last_name,
      cc.cc_state,
      wsite.web_country,
      ws.ws_ext_sales_price,
      ws.ws_ext_ship_cost,
      ws.ws_quantity,
      CASE WHEN i.i_current_price > 100 THEN 'Expensive' ELSE 'Standard' END AS price_category
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d_sold
      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN tpcds.item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_address ca
      ON c.c_current_addr_sk = ca.ca_address_sk
    JOIN tpcds.household_demographics hd
      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN tpcds.inventory inv
      ON i.i_item_sk = inv.inv_item_sk
    JOIN tpcds.date_dim d_inv
      ON inv.inv_date_sk = d_inv.d_date_sk
    JOIN tpcds.web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site wsite
      ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN tpcds.store s
      ON s.s_closed_date_sk = d_inv.d_date_sk
    JOIN tpcds.call_center cc
      ON cc.cc_closed_date_sk = d_inv.d_date_sk
    LEFT JOIN tpcds.catalog_returns cr
      ON ws.ws_order_number = cr.cr_order_number
    LEFT JOIN tpcds.catalog_page cp
      ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN tpcds.reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
      d_sold.d_year = 2001
      AND i.i_current_price BETWEEN 20 AND 200
      AND cc.cc_state = 'CA'
      AND wsite.web_country = 'United States'
      AND ws.ws_ext_ship_cost > 100
      AND i.i_item_sk IN (SELECT ws_item_sk FROM item_common)
  ),
  agg_sales AS (
    SELECT
      d_year,
      price_category,
      COUNT(*) AS total_orders,
      SUM(ws_ext_sales_price) AS total_sales,
      SUM(ws_quantity) AS total_quantity,
      COUNT(DISTINCT c_customer_sk) AS distinct_customers,
      COUNT(DISTINCT i_brand_id) AS distinct_brands
    FROM base
    WHERE NOT EXISTS (
      SELECT 1
      FROM tpcds.catalog_returns cr2
      WHERE cr2.cr_order_number = base.ws_order_number
    )
    GROUP BY d_year, price_category
  )
SELECT
  d_year,
  price_category,
  total_orders,
  total_sales,
  total_quantity,
  distinct_customers,
  distinct_brands,
  total_sales / NULLIF(total_quantity, 0) AS avg_price_per_item
FROM agg_sales
ORDER BY total_sales DESC
LIMIT 100
