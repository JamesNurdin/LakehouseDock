WITH
catalog_data AS (
   SELECT
       cs.cs_order_number                                   AS order_number,
       cs.cs_net_profit                                     AS net_profit,
       cs.cs_ext_sales_price                                AS ext_sales_price,
       cs.cs_quantity                                       AS quantity,
       d.d_year                                             AS d_year,
       i.i_category                                         AS i_category,
       p.p_promo_name                                       AS p_promo_name,
       sm.sm_carrier                                        AS carrier,
       cc.cc_state                                          AS state,
       CASE WHEN cs.cs_net_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag
   FROM catalog_sales cs
   JOIN date_dim d          ON cs.cs_sold_date_sk   = d.d_date_sk
   JOIN time_dim t          ON cs.cs_sold_time_sk   = t.t_time_sk
   JOIN item i              ON cs.cs_item_sk        = i.i_item_sk
   JOIN customer c          ON cs.cs_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON cs.cs_bill_addr_sk   = ca.ca_address_sk
   JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
   JOIN call_center cc      ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp     ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm        ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
   JOIN warehouse w         ON cs.cs_warehouse_sk   = w.w_warehouse_sk
   JOIN promotion p         ON cs.cs_promo_sk       = p.p_promo_sk
   LEFT JOIN catalog_returns cr ON cs.cs_order_number = cr.cr_order_number
   LEFT JOIN reason r            ON cr.cr_reason_sk = r.r_reason_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'BrandX'
     AND p.p_discount_active = 'Y'
     AND sm.sm_carrier = 'UPS'
     AND cc.cc_state = 'CA'
),
store_data AS (
   SELECT
       ss.ss_ticket_number                                 AS order_number,
       ss.ss_net_profit                                    AS net_profit,
       ss.ss_ext_sales_price                               AS ext_sales_price,
       ss.ss_quantity                                      AS quantity,
       d.d_year                                            AS d_year,
       i.i_category                                        AS i_category,
       p.p_promo_name                                      AS p_promo_name,
       NULL                                                AS carrier,
       s.s_state                                           AS state,
       CASE WHEN ss.ss_net_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag
   FROM store_sales ss
   JOIN date_dim d          ON ss.ss_sold_date_sk = d.d_date_sk
   JOIN time_dim t          ON ss.ss_sold_time_sk = t.t_time_sk
   JOIN item i              ON ss.ss_item_sk      = i.i_item_sk
   JOIN customer c          ON ss.ss_customer_sk  = c.c_customer_sk
   JOIN customer_address ca ON ss.ss_addr_sk      = ca.ca_address_sk
   JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
   JOIN store s            ON ss.ss_store_sk     = s.s_store_sk
   JOIN promotion p         ON ss.ss_promo_sk     = p.p_promo_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'BrandX'
     AND p.p_discount_active = 'Y'
),
web_data AS (
   SELECT
       ws.ws_order_number                                 AS order_number,
       ws.ws_net_profit                                   AS net_profit,
       ws.ws_ext_sales_price                              AS ext_sales_price,
       ws.ws_quantity                                     AS quantity,
       d.d_year                                           AS d_year,
       i.i_category                                       AS i_category,
       p.p_promo_name                                     AS p_promo_name,
       sm.sm_carrier                                      AS carrier,
       ws_site.web_country                                 AS state,
       CASE WHEN ws.ws_net_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_flag
   FROM web_sales ws
   JOIN date_dim d          ON ws.ws_sold_date_sk = d.d_date_sk
   JOIN time_dim t          ON ws.ws_sold_time_sk = t.t_time_sk
   JOIN item i              ON ws.ws_item_sk      = i.i_item_sk
   JOIN customer c          ON ws.ws_bill_customer_sk = c.c_customer_sk
   JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
   JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN web_page wp         ON ws.ws_web_page_sk   = wp.wp_web_page_sk
   JOIN web_site ws_site    ON ws.ws_web_site_sk   = ws_site.web_site_sk
   JOIN ship_mode sm        ON ws.ws_ship_mode_sk  = sm.sm_ship_mode_sk
   JOIN promotion p         ON ws.ws_promo_sk      = p.p_promo_sk
   WHERE d.d_year = 2001
     AND i.i_brand = 'BrandX'
     AND p.p_discount_active = 'Y'
     AND sm.sm_carrier = 'UPS'
),
combined AS (
   SELECT DISTINCT * FROM catalog_data
   UNION ALL
   SELECT DISTINCT * FROM store_data
   UNION ALL
   SELECT DISTINCT * FROM web_data
)
SELECT
   order_number,
   net_profit,
   ext_sales_price,
   quantity,
   d_year,
   i_category,
   p_promo_name,
   carrier,
   state,
   profit_flag,
   RANK() OVER (PARTITION BY d_year ORDER BY net_profit DESC)               AS profit_rank,
   SUM(net_profit) OVER (PARTITION BY i_category ORDER BY net_profit
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)                AS cum_profit_by_category
FROM combined
ORDER BY profit_rank
LIMIT 100
