WITH sales_agg AS (
  SELECT
    d.d_year,
    c.c_birth_country,
    i.i_category,
    SUM(ss.ss_net_profit)                       AS store_profit,
    SUM(sr.sr_net_loss)                         AS store_return_loss,
    SUM(cs.cs_net_profit)                       AS catalog_profit,
    SUM(cr.cr_net_loss)                         AS catalog_return_loss,
    SUM(wr.wr_net_loss)                         AS web_return_loss,
    SUM(inv.inv_quantity_on_hand)               AS inventory_qty,
    SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) - SUM(sr.sr_net_loss) - SUM(cr.cr_net_loss) - SUM(wr.wr_net_loss) AS total_profit
  FROM tpcds.date_dim d
  JOIN tpcds.store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
  JOIN tpcds.time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
  JOIN tpcds.store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
   AND sr.sr_ticket_number = ss.ss_ticket_number
  JOIN tpcds.customer c
    ON ss.ss_customer_sk = c.c_customer_sk
  JOIN tpcds.item i
    ON ss.ss_item_sk = i.i_item_sk
  JOIN tpcds.promotion p
    ON ss.ss_promo_sk = p.p_promo_sk
  JOIN tpcds.catalog_sales cs
    ON cs.cs_sold_date_sk = d.d_date_sk
   AND cs.cs_item_sk = i.i_item_sk
  JOIN tpcds.call_center cc
    ON cs.cs_call_center_sk = cc.cc_call_center_sk
  JOIN tpcds.catalog_returns cr
    ON cr.cr_returned_date_sk = d.d_date_sk
   AND cr.cr_item_sk = i.i_item_sk
   AND cr.cr_order_number = cs.cs_order_number
  JOIN tpcds.reason r
    ON sr.sr_reason_sk = r.r_reason_sk
  JOIN tpcds.web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
   AND wr.wr_item_sk = i.i_item_sk
  JOIN tpcds.web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
  JOIN tpcds.inventory inv
    ON inv.inv_date_sk = d.d_date_sk
   AND inv.inv_item_sk = i.i_item_sk
  WHERE
    d.d_year BETWEEN 2000 AND 2002
    AND c.c_birth_country IN ('CHILE', 'PHILIPPINES')
    AND i.i_brand_id = 12
    AND p.p_discount_active = 'Y'
    AND cc.cc_division = 5
    AND t.t_meal_time = 'dinner'
    AND wr.wr_return_quantity > 0
  GROUP BY GROUPING SETS (
    (d.d_year, c.c_birth_country, i.i_category),
    (d.d_year, c.c_birth_country),
    (d.d_year),
    ()
  )
)
SELECT
  sa.d_year,
  sa.c_birth_country,
  sa.i_category,
  sa.total_profit,
  ROW_NUMBER() OVER (PARTITION BY sa.d_year ORDER BY sa.total_profit DESC) AS profit_rank,
  (
    SELECT AVG(cs_sub.cs_net_profit)
    FROM tpcds.catalog_sales cs_sub
    JOIN tpcds.item i_sub ON cs_sub.cs_item_sk = i_sub.i_item_sk
    WHERE i_sub.i_category = sa.i_category
  ) AS avg_category_profit,
  CASE
    WHEN sa.total_profit > (
      SELECT AVG(cs_sub.cs_net_profit)
      FROM tpcds.catalog_sales cs_sub
      JOIN tpcds.item i_sub ON cs_sub.cs_item_sk = i_sub.i_item_sk
      WHERE i_sub.i_category = sa.i_category
    ) * 10 THEN 'HIGH'
    ELSE 'NORMAL'
  END AS profit_level
FROM sales_agg sa
WHERE sa.total_profit IS NOT NULL
ORDER BY sa.d_year, profit_rank
LIMIT 100
