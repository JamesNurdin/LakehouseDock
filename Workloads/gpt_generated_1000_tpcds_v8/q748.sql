WITH
  intersect_items AS (
    SELECT sr.sr_item_sk AS i_item_sk
    FROM store_returns sr
    WHERE sr.sr_return_quantity > 10
    INTERSECT
    SELECT wr.wr_item_sk AS i_item_sk
    FROM web_returns wr
    WHERE wr.wr_return_quantity > 5
  ),
  full_sales_returns AS (
    SELECT
      ss.ss_item_sk,
      ss.ss_sold_date_sk,
      ss.ss_quantity,
      ss.ss_net_paid,
      wr.wr_return_quantity,
      wr.wr_net_loss
    FROM store_sales ss
    FULL OUTER JOIN web_returns wr
      ON ss.ss_item_sk = wr.wr_item_sk
  ),
  base AS (
    SELECT
      cr.cr_returned_date_sk,
      cr.cr_return_amount,
      cr.cr_net_loss,
      i.i_item_sk,
      i.i_item_id,
      i.i_current_price,
      i.i_category,
      ca.ca_state,
      cd.cd_gender,
      hd.hd_buy_potential,
      ib.ib_lower_bound,
      inv.inv_quantity_on_hand,
      r.r_reason_desc,
      sr.sr_return_quantity,
      sr.sr_net_loss AS sr_net_loss,
      wr.wr_return_quantity,
      wr.wr_net_loss AS wr_net_loss,
      s.s_store_name,
      fsr.ss_quantity AS full_ss_quantity,
      fsr.wr_return_quantity AS full_wr_return_quantity
    FROM catalog_returns cr
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    LEFT JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN household_demographics hd
      ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN income_band ib
      ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN store_sales ss
      ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store s
      ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr
      ON wr.wr_item_sk = i.i_item_sk
    LEFT JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
    LEFT JOIN full_sales_returns fsr
      ON fsr.ss_item_sk = i.i_item_sk
    WHERE i.i_current_price > 100.00
      AND ca.ca_state = 'CA'
      AND hd.hd_buy_potential = '>10000'
      AND ib.ib_lower_bound >= 150000
      AND cr.cr_return_amount > 50.00
      AND EXISTS (SELECT 1 FROM intersect_items ii WHERE ii.i_item_sk = i.i_item_sk)
      AND NOT EXISTS (
        SELECT 1 FROM store_returns sr2
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND sr2.sr_return_quantity = cr.cr_return_quantity
      )
  ),
  agg AS (
    SELECT
      ca_state,
      i_category,
      SUM(cr_return_amount) AS total_return_amount,
      SUM(sr_net_loss) AS total_store_return_loss,
      SUM(wr_net_loss) AS total_web_return_loss,
      COUNT(DISTINCT cr_returned_date_sk) AS distinct_return_dates,
      AVG(i_current_price) AS avg_item_price,
      MIN(inv_quantity_on_hand) AS min_qty_on_hand,
      MAX(inv_quantity_on_hand) AS max_qty_on_hand
    FROM base
    GROUP BY ROLLUP (ca_state, i_category)
  )
SELECT
  ca_state,
  i_category,
  total_return_amount,
  total_store_return_loss,
  total_web_return_loss,
  distinct_return_dates,
  avg_item_price,
  min_qty_on_hand,
  max_qty_on_hand,
  ROW_NUMBER() OVER (PARTITION BY ca_state ORDER BY total_return_amount DESC) AS rn_state,
  LAG(total_return_amount) OVER (PARTITION BY ca_state ORDER BY total_return_amount) AS lag_return_amount
FROM agg
ORDER BY ca_state ASC NULLS LAST,
         i_category ASC NULLS LAST
LIMIT 100
