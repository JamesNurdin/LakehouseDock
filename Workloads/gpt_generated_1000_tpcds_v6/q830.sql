WITH item_perf AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        s.s_store_sk,
        s.s_store_name,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_net_profit,
        cs.cs_net_paid,
        ws.ws_net_profit AS web_profit,
        inv.inv_quantity_on_hand,
        w.w_warehouse_id,
        p_store.p_promo_name AS store_promo,
        p_cat.p_promo_name AS catalog_promo,
        p_web.p_promo_name AS web_promo,
        sm.sm_type AS ship_type,
        r.r_reason_desc AS return_reason,
        sr.sr_return_amt,
        wr.wr_return_amt
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p_store ON ss.ss_promo_sk = p_store.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
        AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
        AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p_cat ON cs.cs_promo_sk = p_cat.p_promo_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        AND ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN promotion p_web ON ws.ws_promo_sk = p_web.p_promo_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_warehouse_sk = ws.ws_warehouse_sk
    JOIN warehouse w ON w.w_warehouse_sk = inv.inv_warehouse_sk
    WHERE w.w_country = 'United States'
      AND ss.ss_quantity > 1
      AND inv.inv_quantity_on_hand > 500
)
SELECT
    i_category,
    s_store_name,
    i_item_sk,
    SUM(ss_net_profit) AS total_store_profit,
    SUM(web_profit) AS total_web_profit,
    SUM(cs_net_paid) AS total_catalog_sales,
    RANK() OVER (PARTITION BY i_category ORDER BY SUM(ss_net_profit) DESC) AS profit_rank,
    CASE
        WHEN SUM(ss_net_profit) > 5000 THEN 'HIGH'
        WHEN SUM(ss_net_profit) > 2000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_level,
    (SELECT AVG(inv_quantity_on_hand) FROM inventory) AS avg_inventory_qty
FROM item_perf
GROUP BY i_category, s_store_name, i_item_sk
HAVING COUNT(*) >= 2
ORDER BY total_store_profit DESC
LIMIT 100
