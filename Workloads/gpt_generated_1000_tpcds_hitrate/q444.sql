WITH
  base AS (
    SELECT
      cs.cs_order_number,
      ws.ws_order_number,
      COALESCE(cs.cs_sold_date_sk, ws.ws_sold_date_sk)                                    AS sold_date_sk,
      COALESCE(cs.cs_quantity, 0) + COALESCE(ws.ws_quantity, 0)                         AS total_quantity,
      COALESCE(cs.cs_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)                         AS total_net_paid,
      COALESCE(cs.cs_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)                     AS total_net_profit,
      c.c_customer_id,
      i.i_product_name,
      COALESCE(d_cs.d_year, d_ws.d_year)                                                AS d_year,
      p.p_promo_name,
      cc.cc_name,
      sm.sm_type,
      w.w_warehouse_name,
      r.r_reason_desc                                                                   AS catalog_return_reason,
      wr.r_reason_desc                                                                  AS web_return_reason,
      s.s_store_name,
      site.web_name
    FROM catalog_sales cs
    FULL OUTER JOIN web_sales ws
      ON cs.cs_order_number = ws.ws_order_number
    LEFT JOIN date_dim d_cs
      ON cs.cs_sold_date_sk = d_cs.d_date_sk
    LEFT JOIN date_dim d_ws
      ON ws.ws_sold_date_sk = d_ws.d_date_sk
    LEFT JOIN customer c
      ON (cs.cs_bill_customer_sk = c.c_customer_sk OR ws.ws_bill_customer_sk = c.c_customer_sk)
    LEFT JOIN item i
      ON (cs.cs_item_sk = i.i_item_sk OR ws.ws_item_sk = i.i_item_sk)
    LEFT JOIN promotion p
      ON (cs.cs_promo_sk = p.p_promo_sk OR ws.ws_promo_sk = p.p_promo_sk)
    LEFT JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN ship_mode sm
      ON (cs.cs_ship_mode_sk = sm.sm_ship_mode_sk OR ws.ws_ship_mode_sk = sm.sm_ship_mode_sk)
    LEFT JOIN warehouse w
      ON (cs.cs_warehouse_sk = w.w_warehouse_sk OR ws.ws_warehouse_sk = w.w_warehouse_sk)
    LEFT JOIN catalog_returns cr
      ON cs.cs_order_number = cr.cr_order_number
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN web_returns wr_ret
      ON ws.ws_order_number = wr_ret.wr_order_number
    LEFT JOIN reason wr
      ON wr_ret.wr_reason_sk = wr.r_reason_sk
    LEFT JOIN store s
      ON s.s_closed_date_sk = COALESCE(d_cs.d_date_sk, d_ws.d_date_sk)
    LEFT JOIN web_site site
      ON ws.ws_web_site_sk = site.web_site_sk
    WHERE COALESCE(d_cs.d_year, d_ws.d_year) = 2002
      AND cc.cc_state = 'CA'
      AND sm.sm_type IN ('AIR', 'RAIL')
      AND i.i_brand = 'Brand#12'
      AND p.p_discount_active = 'Y'
  ),
  order_numbers AS (
    SELECT DISTINCT cs_order_number AS order_number FROM catalog_sales WHERE cs_quantity > 5
    INTERSECT
    SELECT DISTINCT ws_order_number FROM web_sales WHERE ws_quantity > 5
  )
SELECT
  b.d_year,
  b.s_store_name,
  b.i_product_name,
  b.total_quantity,
  b.total_net_paid,
  b.total_net_profit,
  CASE WHEN b.total_net_profit > 0 THEN 'Profit' ELSE 'Loss' END                         AS profit_flag,
  RANK() OVER (PARTITION BY b.d_year ORDER BY b.total_net_paid DESC)                 AS sales_rank
FROM base b
WHERE (b.cs_order_number IN (SELECT order_number FROM order_numbers)
       OR b.ws_order_number IN (SELECT order_number FROM order_numbers))
  AND EXISTS (SELECT 1 FROM catalog_returns cr2 WHERE cr2.cr_order_number = b.cs_order_number AND cr2.cr_return_quantity > 0)
ORDER BY b.d_year, sales_rank
LIMIT 100
