WITH agg_inventory AS (
   SELECT
       inv_item_sk,
       inv_warehouse_sk,
       SUM(inv_quantity_on_hand) AS total_qty_on_hand
   FROM inventory TABLESAMPLE BERNOULLI (5)
   GROUP BY inv_item_sk, inv_warehouse_sk
),
base AS (
   SELECT
       cs.cs_order_number,
       cs.cs_sales_price,
       cs.cs_quantity,
       i.i_category,
       i.i_brand,
       s.s_state,
       w.w_city,
       d_sold.d_year,
       p.p_promo_name,
       sm.sm_carrier,
       cc.cc_name,
       cp.cp_department,
       ws_open.web_name      AS web_name_open,
       ws_close.web_name     AS web_name_close,
       agg.total_qty_on_hand,
       sr.sr_return_quantity,
       d_ret.d_year          AS return_year
   FROM catalog_sales cs
   JOIN date_dim d_sold
       ON cs.cs_sold_date_sk = d_sold.d_date_sk
   JOIN call_center cc
       ON cs.cs_call_center_sk = cc.cc_call_center_sk
   JOIN catalog_page cp
       ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
   JOIN ship_mode sm
       ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN warehouse w
       ON cs.cs_warehouse_sk = w.w_warehouse_sk
   JOIN item i
       ON cs.cs_item_sk = i.i_item_sk
   JOIN promotion p
       ON cs.cs_promo_sk = p.p_promo_sk
   LEFT JOIN web_site ws_open
       ON ws_open.web_open_date_sk = d_sold.d_date_sk
   LEFT JOIN web_site ws_close
       ON ws_close.web_close_date_sk = d_sold.d_date_sk
   JOIN agg_inventory agg
       ON agg.inv_item_sk = i.i_item_sk
      AND agg.inv_warehouse_sk = w.w_warehouse_sk
   LEFT JOIN store_returns sr
       ON sr.sr_item_sk = i.i_item_sk
   LEFT JOIN date_dim d_ret
       ON sr.sr_returned_date_sk = d_ret.d_date_sk
   LEFT JOIN store s
       ON sr.sr_store_sk = s.s_store_sk
   LEFT JOIN date_dim d_store_closed
       ON s.s_closed_date_sk = d_store_closed.d_date_sk
   WHERE NOT EXISTS (
        SELECT 1
        FROM store_returns sr2
        JOIN date_dim d_ret2 ON sr2.sr_returned_date_sk = d_ret2.d_date_sk
        WHERE sr2.sr_item_sk = i.i_item_sk
          AND d_ret2.d_year = d_sold.d_year
   )
)
SELECT
    i_category,
    i_brand,
    s_state,
    w_city,
    d_year,
    SUM(cs_sales_price)        AS total_sales,
    SUM(cs_quantity)           AS total_quantity,
    SUM(total_qty_on_hand)     AS total_inventory,
    COUNT(DISTINCT cs_order_number) AS orders_count
FROM base
GROUP BY CUBE (i_category, i_brand, s_state, w_city, d_year)
ORDER BY total_sales DESC
OFFSET 10 ROWS FETCH NEXT 100 ROWS ONLY
