/*
  Goal: Analyze yearly sales performance per store and brand for the year 2001, incorporating catalog, web and store channels, promotional effects, returns, inventory levels and reason codes. The query joins all 16 TPC‑DS tables using only the permitted surrogate‑key relationships, applies several realistic filters, calculates a variety of aggregates, includes a scalar sub‑query and an EXISTS sub‑query, adds window functions, and limits the result to the top 100 rows.
*/
WITH aggregated AS (
   SELECT
       s.s_store_name,
       d_sold.d_year,
       i.i_brand,
       SUM(cs.cs_net_paid)                     AS sum_cs_net_paid,
       SUM(ws.ws_net_paid)                     AS sum_ws_net_paid,
       SUM(sr.sr_return_amt)                  AS sum_sr_return_amt,
       SUM(wr.wr_return_amt)                  AS sum_wr_return_amt,
       SUM(cr.cr_return_amount)               AS sum_cr_return_amount,
       SUM(inv.inv_quantity_on_hand)          AS sum_inventory_qty,
       COUNT(DISTINCT cs.cs_order_number)     AS cnt_orders,
       MIN(cs.cs_net_profit)                  AS min_profit,
       MAX(cs.cs_net_profit)                  AS max_profit,
       (SELECT AVG(cs2.cs_net_profit) FROM catalog_sales cs2) AS avg_catalog_profit
   FROM catalog_sales cs
   JOIN date_dim d_sold               ON cs.cs_sold_date_sk   = d_sold.d_date_sk
   JOIN call_center cc                ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN warehouse w                   ON cs.cs_warehouse_sk   = w.w_warehouse_sk
   JOIN item i                        ON cs.cs_item_sk        = i.i_item_sk
   JOIN promotion p                   ON cs.cs_promo_sk       = p.p_promo_sk
   LEFT JOIN catalog_returns cr      ON cs.cs_order_number   = cr.cr_order_number
   LEFT JOIN reason r_cr             ON cr.cr_reason_sk      = r_cr.r_reason_sk
   LEFT JOIN date_dim d_cr_ret        ON cr.cr_returned_date_sk = d_cr_ret.d_date_sk
   LEFT JOIN inventory inv           ON i.i_item_sk          = inv.inv_item_sk
   LEFT JOIN date_dim d_inv           ON inv.inv_date_sk      = d_inv.d_date_sk
   LEFT JOIN store_returns sr        ON i.i_item_sk          = sr.sr_item_sk
   LEFT JOIN store s                  ON sr.sr_store_sk       = s.s_store_sk
   LEFT JOIN date_dim d_sr_ret        ON sr.sr_returned_date_sk = d_sr_ret.d_date_sk
   LEFT JOIN reason r_sr             ON sr.sr_reason_sk      = r_sr.r_reason_sk
   LEFT JOIN web_sales ws            ON cs.cs_order_number   = ws.ws_order_number
   LEFT JOIN date_dim d_ws_sold       ON ws.ws_sold_date_sk    = d_ws_sold.d_date_sk
   LEFT JOIN web_page wp              ON ws.ws_web_page_sk    = wp.wp_web_page_sk
   LEFT JOIN web_site wsite           ON ws.ws_web_site_sk    = wsite.web_site_sk
   LEFT JOIN date_dim d_ws_ship       ON ws.ws_ship_date_sk    = d_ws_ship.d_date_sk
   LEFT JOIN web_returns wr          ON ws.ws_order_number   = wr.wr_order_number
   LEFT JOIN date_dim d_wr_ret        ON wr.wr_returned_date_sk = d_wr_ret.d_date_sk
   LEFT JOIN reason r_wr             ON wr.wr_reason_sk      = r_wr.r_reason_sk
   WHERE d_sold.d_year = 2001
     AND i.i_current_price > 100
     AND s.s_state = 'CA'
     AND r_sr.r_reason_desc LIKE '%color%'
     AND p.p_discount_active = 'Y'
     AND EXISTS (
         SELECT 1 FROM web_returns wr2
         WHERE wr2.wr_reason_sk = r_wr.r_reason_sk
           AND wr2.wr_return_amt > 500
     )
   GROUP BY s.s_store_name, d_sold.d_year, i.i_brand
)
SELECT
   s_store_name,
   d_year,
   i_brand,
   sum_cs_net_paid,
   sum_ws_net_paid,
   sum_sr_return_amt,
   sum_wr_return_amt,
   sum_cr_return_amount,
   sum_inventory_qty,
   cnt_orders,
   min_profit,
   max_profit,
   avg_catalog_profit,
   SUM(sum_cs_net_paid) OVER (PARTITION BY s_store_name ORDER BY d_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_cs_sales,
   RANK() OVER (PARTITION BY d_year ORDER BY sum_cs_net_paid DESC) AS sales_rank
FROM aggregated
ORDER BY sum_cs_net_paid DESC
LIMIT 100
