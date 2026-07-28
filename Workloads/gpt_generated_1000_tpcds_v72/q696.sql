WITH agg AS (
    SELECT
        s.s_store_id,
        i.i_item_id,
        d.d_year,
        d.d_month_seq,
        SUM(ss.ss_net_profit) AS store_sales_profit,
        SUM(ws.ws_net_profit) AS web_sales_profit,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_qty,
        COUNT(DISTINCT ws.ws_order_number) AS web_order_cnt,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_ticket_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN web_site wsite ON ws.ws_web_site_sk = wsite.web_site_sk
    WHERE d.d_year = 2001
      AND i.i_current_price BETWEEN 5 AND 20
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND ca.ca_country = 'United States'
      AND sm.sm_type = 'AIR'
      AND wp.wp_type = 'article'
      AND wsite.web_country = 'United States'
      AND EXISTS (
          SELECT 1 FROM catalog_page cp
          WHERE cp.cp_start_date_sk = d.d_date_sk
            AND cp.cp_type = 'Catalog'
      )
    GROUP BY s.s_store_id, i.i_item_id, d.d_year, d.d_month_seq
)
SELECT
    agg.s_store_id,
    agg.i_item_id,
    agg.d_year,
    agg.d_month_seq,
    (agg.store_sales_profit + agg.web_sales_profit) AS total_profit,
    agg.avg_inventory_qty,
    agg.web_order_cnt,
    agg.store_ticket_cnt,
    RANK() OVER (PARTITION BY agg.d_year ORDER BY (agg.store_sales_profit + agg.web_sales_profit) DESC) AS profit_rank_year,
    (SELECT AVG(i2.i_current_price) FROM item i2) AS avg_price_all_items
FROM agg
ORDER BY profit_rank_year, total_profit DESC
LIMIT 100
