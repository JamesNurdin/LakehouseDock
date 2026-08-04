WITH
  /* Catalog sales enriched with date, item, catalog page, call center, warehouse and household demographics */
  catalog_data AS (
    SELECT
      cs.cs_sold_date_sk,
      d.d_date,
      i.i_item_id,
      i.i_current_price,
      cs.cs_ext_sales_price,
      cs.cs_net_profit,
      cp.cp_catalog_page_id,
      cc.cc_name,
      w.w_warehouse_name,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM catalog_sales cs
    JOIN date_dim d            ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i                ON cs.cs_item_sk = i.i_item_sk
    JOIN catalog_page cp       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w           ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND i.i_current_price > 50
      AND cc.cc_state = 'CA'
  ),

  /* Store sales enriched with date, item, store and household demographics */
  store_data AS (
    SELECT
      ss.ss_sold_date_sk,
      d.d_date,
      i.i_item_id,
      i.i_current_price,
      ss.ss_ext_sales_price,
      ss.ss_net_profit,
      s.s_store_name,
      s.s_state,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM store_sales ss
    JOIN date_dim d            ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i                ON ss.ss_item_sk = i.i_item_sk
    JOIN store s               ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_month_seq BETWEEN 1200 AND 1210
      AND s.s_state = 'CA'
      AND i.i_current_price BETWEEN 20 AND 200
  ),

  /* Web sales enriched with date, item, web page, warehouse and household demographics */
  web_data AS (
    SELECT
      ws.ws_sold_date_sk,
      d.d_date,
      i.i_item_id,
      i.i_current_price,
      ws.ws_ext_sales_price,
      ws.ws_net_profit,
      wp.wp_url,
      wp.wp_type,
      w.w_warehouse_name,
      hd.hd_income_band_sk,
      ib.ib_lower_bound,
      ib.ib_upper_bound
    FROM web_sales ws
    JOIN date_dim d            ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i                ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp           ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w           ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE d.d_year = 2001
      AND wp.wp_type = 'Home'
      AND i.i_color = 'Blue'
  ),

  /* Inventory snapshots for the same year */
  inventory_data AS (
    SELECT
      inv.inv_date_sk,
      d.d_date,
      i.i_item_id,
      w.w_warehouse_name,
      inv.inv_quantity_on_hand
    FROM inventory inv
    JOIN date_dim d            ON inv.inv_date_sk = d.d_date_sk
    JOIN item i                ON inv.inv_item_sk = i.i_item_sk
    JOIN warehouse w           ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
  ),

  /* UNION of distinct item ids from catalog and store */
  union_keys AS (
    SELECT DISTINCT i_item_id FROM catalog_data
    UNION
    SELECT DISTINCT i_item_id FROM store_data
  ),

  /* INTERSECT of distinct item ids from catalog and web */
  intersect_keys AS (
    SELECT DISTINCT i_item_id FROM catalog_data
    INTERSECT
    SELECT DISTINCT i_item_id FROM web_data
  ),

  /* EXCEPT of distinct item ids: store minus catalog */
  except_keys AS (
    SELECT DISTINCT i_item_id FROM store_data
    EXCEPT
    SELECT DISTINCT i_item_id FROM catalog_data
  ),

  /* LATERAL join to fetch the most recent inventory record per item */
  item_with_inventory AS (
    SELECT
      cd.i_item_id,
      cd.i_current_price,
      cd.cs_ext_sales_price,
      inv.inv_quantity_on_hand,
      inv.w_warehouse_name
    FROM catalog_data cd
    LEFT JOIN LATERAL (
      SELECT inv_quantity_on_hand, w_warehouse_name
      FROM inventory_data inv
      WHERE inv.i_item_id = cd.i_item_id
      ORDER BY inv.d_date DESC
      LIMIT 1
    ) inv ON true
    WHERE cd.cs_ext_sales_price > 0
  ),

  /* Rank items by sales price within each warehouse */
  final_rank AS (
    SELECT
      iwi.i_item_id,
      iwi.i_current_price,
      iwi.cs_ext_sales_price,
      iwi.inv_quantity_on_hand,
      iwi.w_warehouse_name,
      RANK() OVER (PARTITION BY iwi.w_warehouse_name ORDER BY iwi.cs_ext_sales_price DESC) AS sales_rank,
      CASE
        WHEN iwi.inv_quantity_on_hand IS NULL THEN 'No Inventory'
        WHEN iwi.inv_quantity_on_hand < 10 THEN 'Low'
        ELSE 'Sufficient'
      END AS inventory_status
    FROM item_with_inventory iwi
    WHERE iwi.i_current_price > 30
  )
SELECT
  fr.i_item_id,
  fr.i_current_price,
  fr.cs_ext_sales_price,
  fr.inv_quantity_on_hand,
  fr.w_warehouse_name,
  fr.sales_rank,
  fr.inventory_status,
  /* scalar sub‑queries that count the set operations */
  (SELECT COUNT(*) FROM union_keys)      AS union_key_cnt,
  (SELECT COUNT(*) FROM intersect_keys) AS intersect_key_cnt,
  (SELECT COUNT(*) FROM except_keys)    AS except_key_cnt
FROM final_rank fr
WHERE fr.sales_rank <= 10
  AND EXISTS (
        SELECT 1 FROM store_data sd
        WHERE sd.i_item_id = fr.i_item_id
          AND sd.ss_ext_sales_price > 100
      )
ORDER BY fr.sales_rank ASC, fr.i_item_id
LIMIT 100
