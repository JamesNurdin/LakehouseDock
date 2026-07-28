WITH inv_agg AS (
    SELECT
        inv_item_sk,
        inv_warehouse_sk,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk, inv_warehouse_sk
),
sales_data AS (
    SELECT
        i.i_item_id,
        i.i_item_sk,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        s.s_store_name,
        s.s_store_sk,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
        SUM(sr.sr_net_loss) AS total_store_returns_loss,
        SUM(ws.ws_net_profit) AS total_web_sales_profit,
        SUM(wr.wr_net_loss) AS total_web_returns_loss,
        inv_agg.total_on_hand
    FROM item i
    JOIN inv_agg ON i.i_item_sk = inv_agg.inv_item_sk
    JOIN warehouse w ON inv_agg.inv_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk AND cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
                           AND cr.cr_warehouse_sk = w.w_warehouse_sk
                           AND cr.cr_order_number = cs.cs_order_number
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                         AND wr.wr_order_number = ws.ws_order_number
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN reason r_wr ON wr.wr_reason_sk = r_wr.r_reason_sk
    WHERE cs.cs_wholesale_cost > 50
      AND ws.ws_quantity > 50
      AND s.s_state = 'CA'
      AND r_cr.r_reason_desc = 'Customer Not Satisfied'
    GROUP BY
        i.i_item_id,
        i.i_item_sk,
        w.w_warehouse_name,
        w.w_warehouse_sk,
        s.s_store_name,
        s.s_store_sk,
        inv_agg.total_on_hand
    HAVING SUM(cs.cs_net_profit) > 10000
)
SELECT
    sd.i_item_id,
    sd.w_warehouse_name,
    sd.s_store_name,
    sd.total_sales_profit,
    sd.total_catalog_returns_loss,
    sd.total_store_returns_loss,
    sd.total_web_sales_profit,
    sd.total_web_returns_loss,
    sd.total_on_hand,
    RANK() OVER (PARTITION BY sd.i_item_id ORDER BY sd.total_sales_profit DESC) AS sales_profit_rank,
    CASE
        WHEN sd.total_sales_profit > 50000 THEN 'High'
        WHEN sd.total_sales_profit > 20000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    (SELECT MAX(i2.i_current_price) FROM item i2 WHERE i2.i_item_sk = sd.i_item_sk) AS max_price_of_item
FROM sales_data sd
ORDER BY sd.total_sales_profit DESC
LIMIT 100
