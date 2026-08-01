WITH
store_items AS (
  SELECT i_ss.i_item_sk
  FROM store_sales ss
  JOIN item i_ss ON ss.ss_item_sk = i_ss.i_item_sk
  JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
  JOIN store s ON ss.ss_store_sk = s.s_store_sk
  JOIN inventory inv_ss ON inv_ss.inv_item_sk = i_ss.i_item_sk
  WHERE ss.ss_net_paid > 1000
    AND hd_ss.hd_buy_potential = '>10000'
    AND i_ss.i_units = 'Box'
),
catalog_items AS (
  SELECT i_cs.i_item_sk
  FROM catalog_sales cs
  JOIN item i_cs ON cs.cs_item_sk = i_cs.i_item_sk
  JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
  JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
  JOIN inventory inv_cs ON inv_cs.inv_item_sk = i_cs.i_item_sk
  WHERE cs.cs_ext_sales_price > 500
    AND cp.cp_type = 'Promotion'
    AND i_cs.i_manufact_id = 260
),
common_items AS (
  SELECT i_item_sk FROM store_items
  INTERSECT
  SELECT i_item_sk FROM catalog_items
)
SELECT
    s.s_store_name,
    i_main.i_manufact_id,
    hd_ss.hd_buy_potential,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_transactions,
    SUM(ss.ss_net_profit) AS store_net_profit,
    SUM(cs.cs_net_profit) AS catalog_net_profit,
    SUM(ss.ss_quantity) AS store_quantity,
    SUM(cs.cs_quantity) AS catalog_quantity
FROM
    common_items ci
    JOIN item i_main ON ci.i_item_sk = i_main.i_item_sk
    JOIN store_sales ss ON ss.ss_item_sk = i_main.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN inventory inv_main ON inv_main.inv_item_sk = i_main.i_item_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i_main.i_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN household_demographics hd_bill2 ON cs.cs_bill_hdemo_sk = hd_bill2.hd_demo_sk
    JOIN household_demographics hd_ship2 ON cs.cs_ship_hdemo_sk = hd_ship2.hd_demo_sk
WHERE
    s.s_state = 'CA'
    AND i_main.i_category = 'Electronics'
GROUP BY
    s.s_store_name,
    i_main.i_manufact_id,
    hd_ss.hd_buy_potential
LIMIT 100
