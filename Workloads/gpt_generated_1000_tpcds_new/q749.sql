WITH
  -- time dimension aliases for different roles
  t_sold AS (SELECT * FROM time_dim),
  t_return AS (SELECT * FROM time_dim),
  t_ws    AS (SELECT * FROM time_dim),
  t_wr    AS (SELECT * FROM time_dim),

  -- full outer join of store and web returns (keeps unmatched rows from both sides)
  sr_wr_full AS (
    SELECT
      sr.sr_ticket_number,
      sr.sr_return_amt,
      wr.wr_order_number,
      wr.wr_return_amt
    FROM store_returns sr
    FULL OUTER JOIN web_returns wr
      ON sr.sr_ticket_number = wr.wr_order_number
     AND sr.sr_item_sk      = wr.wr_item_sk
  ),

  -- catalog order numbers that have never been returned
  catalog_orders_no_return AS (
    SELECT cs_order_number
    FROM catalog_sales
    EXCEPT
    SELECT cr_order_number
    FROM catalog_returns
  )

SELECT
  s.s_store_name,
  p.p_promo_name,
  i.i_category,
  SUM(ss.ss_net_paid)                                 AS total_sales,
  SUM(COALESCE(cr.cr_return_amount, 0) +
      COALESCE(sr_wr_full.sr_return_amt, 0) +
      COALESCE(sr_wr_full.wr_return_amt, 0))         AS total_returns,
  COUNT(DISTINCT ss.ss_ticket_number)                 AS num_transactions,
  CASE WHEN SUM(ss.ss_net_paid) > 0 THEN 'PROFIT' ELSE 'LOSS' END AS profit_flag,
  (SELECT COUNT(*) FROM catalog_orders_no_return)    AS catalog_orders_without_return
FROM store_sales ss
JOIN t_sold      ON ss.ss_sold_time_sk = t_sold.t_time_sk
JOIN item i      ON ss.ss_item_sk = i.i_item_sk
JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
JOIN store s     ON ss.ss_store_sk = s.s_store_sk
JOIN customer c  ON ss.ss_customer_sk = c.c_customer_sk
LEFT JOIN inventory inv ON ss.ss_item_sk = inv.inv_item_sk

-- store returns are linked to the same sale via ticket number and several other keys
LEFT JOIN store_returns sr
  ON ss.ss_ticket_number = sr.sr_ticket_number
 AND ss.ss_item_sk       = sr.sr_item_sk
 AND ss.ss_customer_sk   = sr.sr_customer_sk
 AND ss.ss_store_sk      = sr.sr_store_sk
JOIN t_return ON sr.sr_return_time_sk = t_return.t_time_sk

-- catalog sales share the same item and time as the store sale
JOIN catalog_sales cs
  ON ss.ss_item_sk = cs.cs_item_sk
 AND ss.ss_sold_time_sk = cs.cs_sold_time_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN t_sold t_cs_time ON cs.cs_sold_time_sk = t_cs_time.t_time_sk

-- catalog returns linked to the original order
LEFT JOIN catalog_returns cr
  ON cs.cs_order_number = cr.cr_order_number
JOIN t_return t_cr_ret_time ON cr.cr_returned_time_sk = t_cr_ret_time.t_time_sk
JOIN call_center cc_ret ON cr.cr_call_center_sk = cc_ret.cc_call_center_sk

-- web sales using the same item and time dimension (different alias)
JOIN web_sales ws
  ON i.i_item_sk = ws.ws_item_sk
 AND t_sold.t_time_sk = ws.ws_sold_time_sk
JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
JOIN t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk

-- join the full‑outer‑joined returns (store & web) to the rest of the query
LEFT JOIN sr_wr_full ON ss.ss_ticket_number = sr_wr_full.sr_ticket_number
                      OR ss.ss_ticket_number = sr_wr_full.wr_order_number
JOIN t_wr ON (sr_wr_full.sr_ticket_number IS NOT NULL AND sr_wr_full.sr_return_amt IS NOT NULL) OR
            (sr_wr_full.wr_order_number IS NOT NULL AND sr_wr_full.wr_return_amt IS NOT NULL)

GROUP BY GROUPING SETS (
  (s.s_store_name, p.p_promo_name),
  (i.i_category)
)
ORDER BY s.s_store_name, p.p_promo_name, i.i_category
