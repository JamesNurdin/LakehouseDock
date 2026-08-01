WITH
  sampled_inventory AS (
    SELECT *
    FROM inventory TABLESAMPLE BERNOULLI (10)
  ),
  item_not_returned AS (
    SELECT i_item_sk FROM item
    EXCEPT
    SELECT sr_item_sk FROM store_returns
  ),
  cp_sub AS (
    SELECT cp.cp_catalog_page_id,
           cp.cp_department,
           d.d_date_sk
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
  ),
  wp_sub AS (
    SELECT wp.wp_web_page_id,
           wp.wp_type,
           d.d_date_sk
    FROM web_page wp
    JOIN date_dim d ON wp.wp_creation_date_sk = d.d_date_sk
  ),
  cp_wp_full AS (
    SELECT cp.cp_catalog_page_id,
           cp.cp_department,
           wp.wp_web_page_id,
           wp.wp_type,
           cp.d_date_sk
    FROM cp_sub cp
    FULL OUTER JOIN wp_sub wp ON cp.d_date_sk = wp.d_date_sk
  ),
  base AS (
    SELECT
      ss.ss_sold_date_sk,
      ss.ss_item_sk,
      ss.ss_ticket_number,
      ss.ss_quantity,
      i.i_current_price,
      d.d_year,
      cd.cd_credit_rating,
      hd.hd_buy_potential,
      ib.ib_lower_bound,
      inv.inv_quantity_on_hand,
      cc.cc_name,
      cp_wp_full.cp_department,
      cp_wp_full.wp_type
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN sampled_inventory inv ON inv.inv_item_sk = i.i_item_sk
                                 AND inv.inv_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN call_center cc ON cc.cc_closed_date_sk = d.d_date_sk
    LEFT JOIN cp_wp_full ON cp_wp_full.d_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND i.i_current_price BETWEEN 20 AND 100
      AND cd.cd_credit_rating = 'Good'
      AND hd.hd_buy_potential = '5000-10000'
      AND ib.ib_lower_bound >= 30000
      AND ss.ss_item_sk IN (SELECT i_item_sk FROM item_not_returned)
  ),
  anti_filtered AS (
    SELECT *
    FROM base b
    WHERE NOT EXISTS (
      SELECT 1
      FROM store_returns sr2
      WHERE sr2.sr_ticket_number = b.ss_ticket_number
        AND sr2.sr_return_quantity > 0
    )
  ),
  agg1 AS (
    SELECT
      d_year,
      cp_department,
      COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
      SUM(ss_quantity) AS total_quantity,
      AVG(i_current_price) AS avg_price,
      MIN(inv_quantity_on_hand) AS min_inventory,
      MAX(inv_quantity_on_hand) AS max_inventory
    FROM anti_filtered
    GROUP BY d_year, cp_department
  ),
  agg2 AS (
    SELECT
      d_year,
      cp_department,
      COUNT(DISTINCT ss_ticket_number) AS distinct_tickets,
      SUM(ss_quantity) * 0.5 AS total_quantity,
      AVG(i_current_price) AS avg_price,
      MIN(inv_quantity_on_hand) AS min_inventory,
      MAX(inv_quantity_on_hand) AS max_inventory
    FROM anti_filtered
    WHERE ss_ticket_number % 2 = 0
    GROUP BY d_year, cp_department
  ),
  union_agg AS (
    SELECT * FROM agg1
    UNION
    SELECT * FROM agg2
  )
SELECT
  d_year,
  cp_department,
  SUM(distinct_tickets) AS total_distinct_tickets,
  SUM(total_quantity) AS total_quantity,
  AVG(avg_price) AS avg_price,
  MIN(min_inventory) AS min_inventory,
  MAX(max_inventory) AS max_inventory
FROM union_agg
GROUP BY d_year, cp_department
ORDER BY total_quantity DESC
LIMIT 100
