WITH sales_agg AS (
    SELECT
        ca.ca_state AS ca_state,
        p.p_promo_id AS p_promo_id,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(cr.cr_net_loss) AS total_catalog_loss,
        SUM(wr.wr_net_loss) AS total_web_return_loss,
        COUNT(*) AS txn_count
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN tpcds.catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_returned_time_sk = t.t_time_sk
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
        AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
        AND ws.ws_warehouse_sk = w.w_warehouse_sk
        AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_promo_sk = p.p_promo_sk
    JOIN tpcds.web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN tpcds.web_site wsit
        ON ws.ws_web_site_sk = wsit.web_site_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_returned_time_sk = t.t_time_sk
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2001
      AND d.d_qoy = 2
      AND d.d_week_seq BETWEEN 10 AND 20
      AND p.p_discount_active = 'Y'
      AND ca.ca_state IN ('CA', 'TX', 'NY')
      AND ws.ws_wholesale_cost > 50
    GROUP BY ca.ca_state, p.p_promo_id
)
SELECT
    ca_state,
    p_promo_id,
    total_store_profit,
    total_web_profit,
    (total_store_profit + total_web_profit) AS combined_profit,
    txn_count,
    (total_store_profit + total_web_profit) / NULLIF(txn_count, 0) AS avg_profit_per_txn,
    (SELECT AVG(total_store_profit) FROM sales_agg) AS avg_store_profit_all
FROM sales_agg
WHERE (total_store_profit + total_web_profit) > 100000
ORDER BY combined_profit DESC
LIMIT 100
