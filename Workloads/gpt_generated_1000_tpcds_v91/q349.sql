WITH
    item_base AS (
        SELECT i.i_item_sk,
               i.i_item_id,
               i.i_item_desc,
               i.i_current_price,
               i.i_category
        FROM item i
        WHERE i.i_current_price > 50
          AND i.i_category = 'Electronics'
    ),
    inv_wh AS (
        SELECT inv.inv_item_sk AS i_item_sk,
               inv.inv_quantity_on_hand,
               w.w_warehouse_sk,
               w.w_warehouse_name AS inventory_warehouse_name,
               w.w_city AS inventory_city,
               w.w_state AS inventory_state,
               inv.inv_warehouse_sk
        FROM inventory inv
        FULL OUTER JOIN warehouse w
          ON inv.inv_warehouse_sk = w.w_warehouse_sk
    ),
    catalog_join AS (
        SELECT 
            i.i_item_sk,
            cr.cr_order_number,
            cr.cr_return_quantity,
            cr.cr_return_amount,
            cr.cr_net_loss,
            cr.cr_returned_date_sk,
            cc.cc_name,
            cp.cp_type,
            r.r_reason_desc,
            t.t_hour,
            hd.hd_income_band_sk,
            ib.ib_lower_bound,
            ib.ib_upper_bound,
            ca.ca_state,
            w.w_warehouse_name AS catalog_warehouse_name
        FROM catalog_returns cr
        JOIN item i ON cr.cr_item_sk = i.i_item_sk
        JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
        JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
        JOIN time_dim t ON cr.cr_returned_time_sk = t.t_time_sk
        JOIN household_demographics hd ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
        LEFT JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
        WHERE cr.cr_return_quantity > 0
          AND ib.ib_lower_bound >= 30000
          AND t.t_hour BETWEEN 9 AND 17
    ),
    store_join AS (
        SELECT 
            i.i_item_sk,
            sr.sr_ticket_number,
            sr.sr_return_quantity,
            sr.sr_return_amt,
            sr.sr_net_loss,
            sr.sr_returned_date_sk,
            r.r_reason_desc AS store_reason,
            t.t_hour AS store_hour,
            hd.hd_income_band_sk,
            ib.ib_upper_bound,
            ca.ca_state
        FROM store_returns sr
        JOIN item i ON sr.sr_item_sk = i.i_item_sk
        JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
        JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
        JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
        WHERE sr.sr_return_quantity > 0
          AND ib.ib_upper_bound <= 200000
          AND ca.ca_state = 'CA'
    ),
    web_join AS (
        SELECT 
            i.i_item_sk,
            ws.ws_order_number,
            ws.ws_quantity,
            ws.ws_net_profit,
            ws.ws_sold_date_sk,
            p.p_promo_name,
            r.r_reason_desc AS web_reason,
            t.t_hour AS web_hour,
            hd.hd_income_band_sk,
            ib.ib_lower_bound,
            ca.ca_state,
            w.w_warehouse_name,
            wr.wr_return_quantity,
            wr.wr_return_amt,
            wr.wr_net_loss
        FROM web_sales ws
        JOIN item i ON ws.ws_item_sk = i.i_item_sk
        JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
        JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
        JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
        JOIN customer_address ca ON ws.ws_bill_addr_sk = ca.ca_address_sk
        LEFT JOIN web_returns wr 
          ON ws.ws_order_number = wr.wr_order_number
         AND ws.ws_item_sk = wr.wr_item_sk
        LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE ws.ws_quantity > 0
          AND w.w_state = 'WA'
          AND p.p_discount_active = 'Y'
    ),
    combined AS (
        SELECT 
            ib.i_item_sk,
            ib.i_item_id,
            ib.i_item_desc,
            ib.i_current_price,
            ib.i_category,
            COALESCE(cd.cr_net_loss, 0) AS catalog_net_loss,
            COALESCE(sd.sr_net_loss, 0) AS store_net_loss,
            COALESCE(wd.ws_net_profit, 0) AS web_net_profit,
            cd.r_reason_desc AS catalog_reason,
            sd.store_reason,
            wd.web_reason,
            cd.t_hour AS catalog_hour,
            sd.store_hour,
            wd.web_hour,
            cd.cc_name,
            cd.cp_type,
            wd.p_promo_name,
            wd.w_warehouse_name AS web_warehouse_name,
            inv.inv_quantity_on_hand,
            inv.inventory_warehouse_name,
            inv.inventory_city,
            inv.inventory_state
        FROM item_base ib
        LEFT JOIN catalog_join cd ON ib.i_item_sk = cd.i_item_sk
        LEFT JOIN store_join sd ON ib.i_item_sk = sd.i_item_sk
        LEFT JOIN web_join wd ON ib.i_item_sk = wd.i_item_sk
        LEFT JOIN inv_wh inv ON ib.i_item_sk = inv.i_item_sk
    )
SELECT 
    i_item_id,
    i_category,
    i_current_price,
    catalog_net_loss,
    store_net_loss,
    web_net_profit,
    (catalog_net_loss + store_net_loss - web_net_profit) AS total_loss,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY (catalog_net_loss + store_net_loss - web_net_profit) DESC) AS loss_rank,
    CASE 
        WHEN catalog_net_loss >= store_net_loss AND catalog_net_loss >= web_net_profit THEN 'Catalog'
        WHEN store_net_loss >= catalog_net_loss AND store_net_loss >= web_net_profit THEN 'Store'
        ELSE 'Web' 
    END AS dominant_channel,
    inv_quantity_on_hand,
    inventory_warehouse_name,
    inventory_city,
    inventory_state
FROM combined
WHERE EXISTS (
    SELECT 1
    FROM promotion p2
    WHERE p2.p_item_sk = combined.i_item_sk
      AND p2.p_discount_active = 'Y'
)
INTERSECT
SELECT 
    i_item_id,
    i_category,
    i_current_price,
    catalog_net_loss,
    store_net_loss,
    web_net_profit,
    (catalog_net_loss + store_net_loss - web_net_profit) AS total_loss,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY (catalog_net_loss + store_net_loss - web_net_profit) DESC) AS loss_rank,
    CASE 
        WHEN catalog_net_loss >= store_net_loss AND catalog_net_loss >= web_net_profit THEN 'Catalog'
        WHEN store_net_loss >= catalog_net_loss AND store_net_loss >= web_net_profit THEN 'Store'
        ELSE 'Web' 
    END AS dominant_channel,
    inv_quantity_on_hand,
    inventory_warehouse_name,
    inventory_city,
    inventory_state
FROM combined
WHERE (catalog_net_loss + store_net_loss - web_net_profit) > 5000
  AND i_current_price > 200
ORDER BY total_loss DESC
LIMIT 100
