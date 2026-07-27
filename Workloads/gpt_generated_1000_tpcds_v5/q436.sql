WITH sales_cte AS (
  SELECT
    cs.cs_order_number,
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    cs.cs_warehouse_sk,
    cs.cs_quantity,
    cs.cs_net_paid,
    cs.cs_net_profit,
    d.d_date,
    d.d_year,
    d.d_month_seq,
    i.i_item_id,
    i.i_class_id,
    i.i_manufact_id,
    w.w_warehouse_name,
    w.w_state,
    inv.inv_quantity_on_hand,
    cp.cp_department,
    cp.cp_catalog_number,
    s.s_store_id,
    s.s_county,
    s.s_floor_space
  FROM catalog_sales cs
  JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
  JOIN item i
    ON cs.cs_item_sk = i.i_item_sk
  JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
  JOIN catalog_page cp
    ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
  JOIN store s
    ON s.s_closed_date_sk = d.d_date_sk
  LEFT JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
    AND inv.inv_item_sk = i.i_item_sk
    AND inv.inv_warehouse_sk = w.w_warehouse_sk
  WHERE d.d_year = 2001
    AND s.s_county = 'Gogebic County'
    AND i.i_class_id = 15
    AND w.w_state = 'CA'
    AND cs.cs_quantity > 0
)
SELECT
  sc.cs_order_number,
  sc.d_date,
  sc.s_store_id,
  sc.i_item_id,
  sc.cs_quantity,
  sc.cs_net_paid,
  sc.cs_net_profit,
  CASE
    WHEN sc.cs_net_profit / NULLIF(sc.cs_net_paid, 0) > 0.2 THEN 'High'
    ELSE 'Low'
  END AS profit_category,
  RANK() OVER (PARTITION BY sc.s_store_id ORDER BY sc.cs_net_profit DESC) AS profit_rank_within_store,
  ROW_NUMBER() OVER (PARTITION BY sc.d_year, sc.d_month_seq ORDER BY sc.cs_net_paid DESC) AS sales_rank_monthly
FROM sales_cte sc
LIMIT 100
