WITH
  joined_data AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_store_sk AS s_store_sk,
      s.s_store_name,
      s.s_state,
      i.i_item_sk,
      i.i_item_id,
      i.i_current_price,
      p.p_promo_id,
      p.p_discount_active,
      hd.hd_demo_sk,
      ib.ib_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound,
      cp.cp_catalog_page_id,
      cp.cp_type,
      r.r_reason_desc,
      inv.inv_quantity_on_hand,
      ss.ss_net_profit,
      sr.sr_return_amt_inc_tax,
      wr.wr_return_amt_inc_tax,
      wp.wp_type
    FROM store_sales ss
    JOIN item i                ON ss.ss_item_sk = i.i_item_sk
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p          ON ss.ss_promo_sk = p.p_promo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_returns sr      ON sr.sr_item_sk = ss.ss_item_sk
                                 AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN reason r              ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_returns cr    ON cr.cr_item_sk = i.i_item_sk
    JOIN catalog_page cp       ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN web_returns wr        ON wr.wr_item_sk = i.i_item_sk
    JOIN web_page wp           ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv         ON inv.inv_item_sk = i.i_item_sk
    WHERE s.s_state = 'TX'
      AND p.p_discount_active = 'Y'
      AND ib.ib_lower_bound >= 100000
      AND cp.cp_type = 'A'
      AND wp.wp_type = 'home'
      AND inv.inv_quantity_on_hand > 0
      AND i.i_current_price BETWEEN 10 AND 100
  ),

  items_sold AS (
    SELECT DISTINCT i_item_sk FROM joined_data
  ),

  items_returned AS (
    SELECT DISTINCT sr_item_sk AS i_item_sk FROM store_returns
  ),

  items_sold_not_returned AS (
    SELECT i_item_sk FROM items_sold
    EXCEPT
    SELECT i_item_sk FROM items_returned
  ),

  promo_items_tx AS (
    SELECT DISTINCT i_item_sk FROM joined_data
    INTERSECT
    SELECT p_item_sk FROM promotion WHERE p_discount_active = 'Y'
  ),

  union_returns AS (
    SELECT sr.sr_return_amt_inc_tax AS return_amt,
           sr.sr_store_sk            AS store_sk
    FROM   store_returns sr
    UNION
    SELECT wr.wr_return_amt_inc_tax AS return_amt,
           NULL                       AS store_sk
    FROM   web_returns wr
  ),

  filtered_data AS (
    SELECT jd.*
    FROM   joined_data jd
    WHERE  NOT EXISTS (
      SELECT 1
      FROM   catalog_returns cr2
      WHERE  cr2.cr_order_number = jd.ss_sold_date_sk
    )
  ),

  agg_rollup AS (
    SELECT
      fd.s_store_sk,
      fd.i_item_sk,
      SUM(fd.ss_net_profit) AS total_profit,
      SUM(ur.return_amt)    AS total_return
    FROM   filtered_data fd
    LEFT JOIN union_returns ur ON ur.store_sk = fd.s_store_sk
    GROUP BY ROLLUP (fd.s_store_sk, fd.i_item_sk)
  )
SELECT
  s_store_sk,
  i_item_sk,
  total_profit,
  total_return,
  ROW_NUMBER() OVER (PARTITION BY s_store_sk ORDER BY total_profit DESC) AS profit_rank,
  CASE WHEN total_profit > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_category
FROM   agg_rollup
WHERE  i_item_sk IN (SELECT i_item_sk FROM items_sold_not_returned)
ORDER BY total_profit DESC NULLS LAST
LIMIT 100
