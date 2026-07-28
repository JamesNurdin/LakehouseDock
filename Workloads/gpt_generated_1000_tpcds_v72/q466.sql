WITH
  /*
   * Base fact rows from catalog_sales with all required dimensions and related facts.
   */
  base AS (
    SELECT
      cs.cs_sold_date_sk,
      cs.cs_sold_time_sk,
      cs.cs_ship_date_sk,
      cs.cs_bill_customer_sk,
      cs.cs_bill_cdemo_sk,
      cs.cs_bill_hdemo_sk,
      cs.cs_bill_addr_sk,
      cs.cs_ship_customer_sk,
      cs.cs_ship_cdemo_sk,
      cs.cs_ship_hdemo_sk,
      cs.cs_ship_addr_sk,
      cs.cs_call_center_sk,
      cs.cs_catalog_page_sk,
      cs.cs_ship_mode_sk,
      cs.cs_warehouse_sk,
      cs.cs_item_sk,
      cs.cs_promo_sk,
      cs.cs_order_number,
      cs.cs_quantity,
      cs.cs_net_paid,
      cs.cs_net_profit,
      cs.cs_ext_sales_price
    FROM tpcds.catalog_sales cs
  ),

  /*
   * Aggregated view that joins every selected table using only the allowed keys.
   * It also applies the required filter predicates.
   */
  agg AS (
    SELECT
      d.d_year,
      i.i_category,
      i.i_brand,
      SUM(cs.cs_net_paid)                         AS total_catalog_sales,
      SUM(cs.cs_net_profit)                       AS total_catalog_profit,
      COUNT(DISTINCT cs.cs_order_number)          AS catalog_orders,
      COUNT(cr.cr_order_number)                   AS catalog_return_cnt,
      COUNT(DISTINCT ws.ws_order_number)          AS web_orders_cnt,
      SUM(ws.ws_net_paid)                         AS total_web_sales,
      MIN(i.i_current_price)                      AS min_price,
      MAX(i.i_current_price)                      AS max_price
    FROM base cs
    /* date and time dimensions */
    JOIN tpcds.date_dim d        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t        ON cs.cs_sold_time_sk = t.t_time_sk
    /* call center and ship mode */
    JOIN tpcds.call_center cc   ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.ship_mode sm     ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    /* catalog page */
    JOIN tpcds.catalog_page cp  ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    /* warehouse */
    JOIN tpcds.warehouse w      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    /* item and promotion */
    JOIN tpcds.item i           ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.promotion p      ON cs.cs_promo_sk = p.p_promo_sk
    /* household demographics and addresses for bill and ship sides */
    JOIN tpcds.household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN tpcds.customer_address ca_bill      ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN tpcds.customer_address ca_ship      ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    /* catalog returns and reason */
    JOIN tpcds.catalog_returns cr   ON cs.cs_order_number = cr.cr_order_number
    JOIN tpcds.reason r            ON cr.cr_reason_sk = r.r_reason_sk
    /* web sales (joined on the same item and date) */
    JOIN tpcds.web_sales ws        ON cs.cs_item_sk = ws.ws_item_sk
                                   AND cs.cs_sold_date_sk = ws.ws_sold_date_sk
    /* web page and web site */
    JOIN tpcds.web_page wp         ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site we         ON ws.ws_web_site_sk = we.web_site_sk
    /* web returns */
    JOIN tpcds.web_returns wr      ON ws.ws_order_number = wr.wr_order_number
    /* inventory */
    JOIN tpcds.inventory inv       ON cs.cs_item_sk = inv.inv_item_sk
                                   AND cs.cs_sold_date_sk = inv.inv_date_sk
    /* store (joined via its closed date) */
    JOIN tpcds.store s             ON s.s_closed_date_sk = d.d_date_sk
    WHERE
      d.d_year BETWEEN 1999 AND 2001                     -- year filter (5 predicates total)
      AND i.i_current_price > 20
      AND cc.cc_country = 'United States'
      AND sm.sm_type = 'AIR'
      AND wp.wp_autogen_flag = 'N'
      AND we.web_name LIKE '%Shop%'
    GROUP BY
      d.d_year,
      i.i_category,
      i.i_brand
    HAVING COUNT(*) > 10
  )
SELECT DISTINCT
  d_year,
  i_category,
  i_brand,
  total_catalog_sales,
  total_web_sales,
  total_catalog_profit,
  catalog_orders,
  web_orders_cnt,
  catalog_return_cnt,
  RANK() OVER (PARTITION BY d_year ORDER BY total_catalog_sales DESC) AS sales_rank,
  CASE WHEN total_catalog_profit > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag
FROM agg
ORDER BY d_year DESC, sales_rank
LIMIT 100
