/* Goal: Identify top‑selling items by category, comparing two promotional scenarios, while demonstrating sampling, right‑outer joins, grouping sets, window ranking, and a scalar subquery. */
WITH
  /* Sampled inventory aggregation (pre‑aggregate) */
  inv_agg AS (
    SELECT
      inv_item_sk,
      SUM(inv_quantity_on_hand) AS total_on_hand,
      COUNT(*) AS inventory_days
    FROM inventory
    TABLESAMPLE BERNOULLI (10)   -- sample 10 % of rows
    GROUP BY inv_item_sk
  ),

  /* Returns aggregation per item */
  returns_agg AS (
    SELECT
      wr_item_sk,
      SUM(wr_return_quantity) AS total_return_qty,
      SUM(wr_net_loss)        AS total_net_loss
    FROM web_returns
    GROUP BY wr_item_sk
  ),

  /* Fact source filtered by a scalar sub‑query */
  base_sales AS (
    SELECT
      ws_sold_date_sk,
      ws_sold_time_sk,
      ws_ship_date_sk,
      ws_item_sk,
      ws_bill_hdemo_sk,
      ws_ship_hdemo_sk,
      ws_ship_mode_sk,
      ws_promo_sk,
      ws_order_number,
      ws_quantity,
      ws_sales_price,
      ws_ext_sales_price,
      ws_ext_discount_amt,
      ws_net_profit
    FROM web_sales
    WHERE ws_quantity > (
      SELECT MAX(ws_quantity)
      FROM web_sales
      WHERE ws_sold_date_sk = 2450829
    )
  ),

  /* First promotional scenario (discount inactive, class = dresses, year 1998) */
  scenario_one AS (
    SELECT
      d_sold.d_year,
      i.i_category,
      i.i_brand,
      sm.sm_type,
      cp.cp_catalog_page_id,
      p.p_promo_name,
      ws.ws_quantity,
      ws.ws_sales_price,
      ws.ws_ext_discount_amt,
      SUM(ws.ws_ext_sales_price)               AS total_sales,
      COUNT(*)                                 AS order_cnt,
      COALESCE(inv.total_on_hand, 0)           AS total_on_hand,
      COALESCE(ret.total_return_qty, 0)        AS total_return_qty
    FROM base_sales ws
    JOIN date_dim d_sold      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold      ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN item i               ON ws.ws_item_sk = i.i_item_sk
    RIGHT OUTER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT  JOIN promotion p   ON ws.ws_promo_sk = p.p_promo_sk
    LEFT  JOIN inv_agg inv   ON ws.ws_item_sk = inv.inv_item_sk
    LEFT  JOIN returns_agg ret ON ws.ws_item_sk = ret.wr_item_sk
    LEFT  JOIN catalog_page cp ON cp.cp_end_date_sk = d_sold.d_date_sk
    LEFT  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d_sold.d_year = 1998
      AND p.p_discount_active = 'N'
      AND i.i_class = 'dresses'
    GROUP BY GROUPING SETS (
      (d_sold.d_year, i.i_category, i.i_brand, sm.sm_type, cp.cp_catalog_page_id,
       p.p_promo_name, ws.ws_quantity, ws.ws_sales_price, ws.ws_ext_discount_amt,
       inv.total_on_hand, ret.total_return_qty),
      (d_sold.d_year, i.i_category, sm.sm_type, cp.cp_catalog_page_id,
       p.p_promo_name, ws.ws_quantity, ws.ws_sales_price, ws.ws_ext_discount_amt,
       inv.total_on_hand, ret.total_return_qty),
      (d_sold.d_year, sm.sm_type, cp.cp_catalog_page_id,
       p.p_promo_name, ws.ws_quantity, ws.ws_sales_price, ws.ws_ext_discount_amt,
       inv.total_on_hand, ret.total_return_qty)
    )
  ),

  /* Second promotional scenario (discount active, class = fragrances, year 1999) */
  scenario_two AS (
    SELECT
      d_sold.d_year,
      i.i_category,
      i.i_brand,
      sm.sm_type,
      cp.cp_catalog_page_id,
      p.p_promo_name,
      ws.ws_quantity,
      ws.ws_sales_price,
      ws.ws_ext_discount_amt,
      SUM(ws.ws_ext_sales_price)               AS total_sales,
      COUNT(*)                                 AS order_cnt,
      COALESCE(inv.total_on_hand, 0)           AS total_on_hand,
      COALESCE(ret.total_return_qty, 0)        AS total_return_qty
    FROM base_sales ws
    JOIN date_dim d_sold      ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN item i               ON ws.ws_item_sk = i.i_item_sk
    RIGHT OUTER JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT  JOIN promotion p   ON ws.ws_promo_sk = p.p_promo_sk
    LEFT  JOIN inv_agg inv   ON ws.ws_item_sk = inv.inv_item_sk
    LEFT  JOIN returns_agg ret ON ws.ws_item_sk = ret.wr_item_sk
    LEFT  JOIN catalog_page cp ON cp.cp_end_date_sk = d_sold.d_date_sk
    LEFT  JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE d_sold.d_year = 1999
      AND p.p_discount_active = 'Y'
      AND i.i_class = 'fragrances'
    GROUP BY GROUPING SETS (
      (d_sold.d_year, i.i_category, i.i_brand, sm.sm_type, cp.cp_catalog_page_id,
       p.p_promo_name, ws.ws_quantity, ws.ws_sales_price, ws.ws_ext_discount_amt,
       inv.total_on_hand, ret.total_return_qty),
      (d_sold.d_year, i.i_category, sm.sm_type, cp.cp_catalog_page_id,
       p.p_promo_name, ws.ws_quantity, ws.ws_sales_price, ws.ws_ext_discount_amt,
       inv.total_on_hand, ret.total_return_qty),
      (d_sold.d_year, sm.sm_type, cp.cp_catalog_page_id,
       p.p_promo_name, ws.ws_quantity, ws.ws_sales_price, ws.ws_ext_discount_amt,
       inv.total_on_hand, ret.total_return_qty)
    )
  ),

  /* Apply ranking and case logic to each scenario */
  ranked_one AS (
    SELECT
      d_year,
      i_category,
      i_brand,
      sm_type,
      cp_catalog_page_id,
      total_sales,
      order_cnt,
      total_on_hand,
      total_return_qty,
      p_promo_name,
      ws_quantity,
      ws_sales_price,
      ws_ext_discount_amt,
      ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS category_sales_rank,
      CASE WHEN ws_ext_discount_amt > 0 THEN 'DISCOUNT' ELSE 'FULL' END AS discount_flag
    FROM scenario_one
  ),

  ranked_two AS (
    SELECT
      d_year,
      i_category,
      i_brand,
      sm_type,
      cp_catalog_page_id,
      total_sales,
      order_cnt,
      total_on_hand,
      total_return_qty,
      p_promo_name,
      ws_quantity,
      ws_sales_price,
      ws_ext_discount_amt,
      ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_sales DESC) AS category_sales_rank,
      CASE WHEN ws_ext_discount_amt > 0 THEN 'DISCOUNT' ELSE 'FULL' END AS discount_flag
    FROM scenario_two
  )

SELECT *
FROM ranked_one
WHERE category_sales_rank <= 10
UNION DISTINCT
SELECT *
FROM ranked_two
WHERE category_sales_rank <= 10
ORDER BY d_year DESC, total_sales DESC
LIMIT 100
