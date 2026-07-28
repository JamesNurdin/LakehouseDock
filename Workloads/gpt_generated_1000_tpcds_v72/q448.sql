WITH
  catalog_sales_pre AS (
    SELECT
      cs.cs_sold_date_sk       AS sold_date_sk,
      cs.cs_sold_time_sk       AS sold_time_sk,
      cs.cs_item_sk            AS item_sk,
      cs.cs_quantity           AS quantity,
      cs.cs_net_profit         AS net_profit,
      cs.cs_ext_sales_price    AS ext_sales_price,
      cs.cs_promo_sk           AS promo_sk,
      cs.cs_call_center_sk     AS call_center_sk,
      cs.cs_catalog_page_sk    AS catalog_page_sk,
      cs.cs_ship_mode_sk       AS ship_mode_sk,
      cs.cs_warehouse_sk       AS warehouse_sk,
      cs.cs_bill_customer_sk   AS bill_customer_sk,
      'catalog'                AS sales_channel
    FROM tpcds.catalog_sales cs
    JOIN tpcds.date_dim d           ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t           ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i               ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.promotion p          ON cs.cs_promo_sk = p.p_promo_sk
    JOIN tpcds.call_center cc      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w         ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.catalog_returns cr
           ON cr.cr_order_number = cs.cs_order_number
    LEFT JOIN tpcds.reason r         ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450815 AND 2454820      -- approx. 2000‑01‑01 to 2001‑01‑01
      AND cs.cs_quantity > 1
      AND cs.cs_net_profit > 0
      AND p.p_discount_active = 'Y'
      AND w.w_warehouse_sq_ft > 50000
      AND cc.cc_employees >= 50
  ),
  web_sales_pre AS (
    SELECT
      ws.ws_sold_date_sk       AS sold_date_sk,
      ws.ws_sold_time_sk       AS sold_time_sk,
      ws.ws_item_sk            AS item_sk,
      ws.ws_quantity           AS quantity,
      ws.ws_net_profit         AS net_profit,
      ws.ws_ext_sales_price    AS ext_sales_price,
      ws.ws_promo_sk           AS promo_sk,
      ws.ws_ship_mode_sk       AS ship_mode_sk,
      ws.ws_warehouse_sk       AS warehouse_sk,
      ws.ws_bill_customer_sk   AS bill_customer_sk,
      ws.ws_web_page_sk        AS web_page_sk,
      ws.ws_web_site_sk        AS web_site_sk,
      'web'                    AS sales_channel
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d           ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t           ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN tpcds.item i               ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.promotion p          ON ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w         ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_page wp         ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site we         ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN tpcds.web_returns wr
           ON wr.wr_order_number = ws.ws_order_number
    LEFT JOIN tpcds.reason r         ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ws.ws_sold_date_sk BETWEEN 2450815 AND 2454820
      AND ws.ws_quantity > 1
      AND ws.ws_net_profit > 0
      AND p.p_discount_active = 'Y'
      AND w.w_warehouse_sq_ft > 50000
      AND we.web_tax_percentage < 5
  ),
  sales_union AS (
    SELECT * FROM catalog_sales_pre
    UNION ALL
    SELECT * FROM web_sales_pre
  ),
  category_profit AS (
    SELECT
      i.i_category                                    AS category,
      su.sales_channel                               AS sales_channel,
      SUM(su.net_profit)                             AS total_profit,
      CASE WHEN SUM(su.net_profit) > 10000 THEN 'High' ELSE 'Low' END AS profit_level
    FROM sales_union su
    JOIN tpcds.item i                               ON su.item_sk = i.i_item_sk
    JOIN tpcds.promotion p                         ON su.promo_sk = p.p_promo_sk
    JOIN tpcds.ship_mode sm                        ON su.ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w                         ON su.warehouse_sk = w.w_warehouse_sk
    LEFT JOIN tpcds.customer c                    ON su.bill_customer_sk = c.c_customer_sk
    LEFT JOIN tpcds.household_demographics hd      ON c.c_current_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN tpcds.customer_address ca            ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN tpcds.date_dim d                     ON su.sold_date_sk = d.d_date_sk
    LEFT JOIN tpcds.time_dim t                     ON su.sold_time_sk = t.t_time_sk
    WHERE EXISTS (
          SELECT 1
          FROM tpcds.store_returns sr
          JOIN tpcds.store s ON sr.sr_store_sk = s.s_store_sk
          WHERE sr.sr_item_sk = su.item_sk
            AND sr.sr_returned_date_sk = su.sold_date_sk
            AND sr.sr_return_quantity > 0
            AND s.s_number_employees >= 20
        )
    GROUP BY i.i_category, su.sales_channel
  )
SELECT
  cp.category,
  cp.sales_channel,
  cp.total_profit,
  cp.profit_level,
  RANK() OVER (PARTITION BY cp.sales_channel ORDER BY cp.total_profit DESC) AS profit_rank,
  (SELECT AVG(cp2.total_profit) FROM category_profit cp2)                     AS avg_category_profit
FROM category_profit cp
ORDER BY cp.sales_channel, profit_rank
LIMIT 100
