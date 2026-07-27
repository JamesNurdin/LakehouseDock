/*
  Goal: Produce a sales‑performance summary per store, item category and promotion, combining data from all 15 TPC‑DS tables. The query joins store, catalog and web sales and returns, links them through shared dimensions (item, time, customer, address, promotion, warehouse, etc.), filters to items that have at least one active promotion, aggregates revenue and return loss, and limits the result to the top 100 rows.
*/
SELECT
    s.s_store_name,
    s.s_state,
    i.i_category,
    p.p_promo_name,
    SUM(ss.ss_net_paid)                 AS total_store_sales,
    SUM(sr.sr_net_loss)                 AS total_store_returns,
    SUM(cs.cs_net_paid)                 AS total_catalog_sales,
    SUM(ws.ws_net_paid)                 AS total_web_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS num_store_transactions,
    AVG(ws.ws_ext_sales_price)          AS avg_web_sale_price
FROM
    store_sales ss
    JOIN time_dim t_sales ON ss.ss_sold_time_sk = t_sales.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    /* Store returns linked by ticket number and item */
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
                         AND sr.sr_item_sk = ss.ss_item_sk
    JOIN time_dim t_ret ON sr.sr_return_time_sk = t_ret.t_time_sk
    /* Catalog sales linked through the shared item */
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN time_dim t_cat ON cs.cs_sold_time_sk = t_cat.t_time_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w1 ON cs.cs_warehouse_sk = w1.w_warehouse_sk
    /* Web sales linked through the same item */
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t_web ON ws.ws_sold_time_sk = t_web.t_time_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN warehouse w2 ON ws.ws_warehouse_sk = w2.w_warehouse_sk
    JOIN promotion p2 ON ws.ws_promo_sk = p2.p_promo_sk
    /* Web returns linked to web sales */
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
                        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN time_dim t_wr ON wr.wr_returned_time_sk = t_wr.t_time_sk
    JOIN web_page wp2 ON wr.wr_web_page_sk = wp2.wp_web_page_sk
WHERE
    EXISTS (
        SELECT 1
        FROM promotion p_active
        WHERE p_active.p_item_sk = i.i_item_sk
          AND p_active.p_discount_active = 'Y'
    )
GROUP BY
    s.s_store_name,
    s.s_state,
    i.i_category,
    p.p_promo_name
ORDER BY
    total_store_sales DESC
LIMIT 100
