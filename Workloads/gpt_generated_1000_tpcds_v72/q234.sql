/*
Goal: Analyze profitability and inventory per store for the year 2001, ranking stores by the combined catalog and web profit while applying several business‑logic filters.
*/
WITH joined_data AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit AS cs_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        cr.cr_net_loss AS cr_net_loss,
        wr.wr_net_loss AS wr_net_loss,
        i.i_item_id,
        i.i_product_name,
        w.w_warehouse_name,
        cc.cc_name,
        s.s_store_name,
        d_sold.d_year,
        d_sold.d_date,
        p.p_promo_name,
        r.r_reason_desc,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN date_dim d_sold
      ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
      ON cs.cs_sold_time_sk = t_sold.t_time_sk
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp
      ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w
      ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN item i
      ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r
      ON cr.cr_reason_sk = r.r_reason_sk
    JOIN web_sales ws
      ON ws.ws_item_sk = i.i_item_sk
     AND ws.ws_warehouse_sk = w.w_warehouse_sk
     AND ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site website
      ON ws.ws_web_site_sk = website.web_site_sk
    JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_item_sk = i.i_item_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
     AND inv.inv_warehouse_sk = w.w_warehouse_sk
     AND inv.inv_date_sk = d_sold.d_date_sk
    JOIN store s
      ON s.s_closed_date_sk = d_sold.d_date_sk
    JOIN date_dim d_cp_start
      ON cp.cp_start_date_sk = d_cp_start.d_date_sk
    WHERE d_sold.d_year = 2001
      AND i.i_brand = 'Brand#12'
      AND w.w_state = 'CA'
      AND cc.cc_class = 'C'
      AND r.r_reason_desc LIKE '%late%'
),
agg_data AS (
    SELECT
        s_store_name,
        d_year,
        SUM(cs_net_profit)                 AS total_catalog_profit,
        SUM(ws_net_profit)                 AS total_web_profit,
        SUM(cr_net_loss)                   AS total_catalog_return_loss,
        SUM(wr_net_loss)                   AS total_web_return_loss,
        SUM(inv_quantity_on_hand)          AS total_inventory_on_hand,
        COUNT(DISTINCT i_item_id)          AS distinct_items_sold
    FROM joined_data
    GROUP BY s_store_name, d_year
    HAVING SUM(cs_net_profit) > 10000
)
SELECT
    s_store_name,
    d_year,
    total_catalog_profit,
    total_web_profit,
    total_catalog_return_loss,
    total_web_return_loss,
    total_inventory_on_hand,
    distinct_items_sold,
    RANK() OVER (PARTITION BY d_year ORDER BY (total_catalog_profit + total_web_profit) DESC) AS profit_rank
FROM agg_data
ORDER BY profit_rank
LIMIT 100
