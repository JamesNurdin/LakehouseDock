WITH inv_summary AS (
    SELECT inv_item_sk,
           SUM(inv_quantity_on_hand) AS total_on_hand
    FROM inventory
    GROUP BY inv_item_sk
),
sales_agg AS (
    SELECT
        i.i_item_sk AS item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_current_price,
        inv.total_on_hand,
        SUM(cs.cs_net_profit) AS total_sales_net_profit,
        SUM(cr.cr_net_loss) AS total_catalog_returns_loss,
        SUM(sr.sr_net_loss) AS total_store_returns_loss,
        SUM(ws.ws_net_profit) AS total_web_sales_net_profit,
        COALESCE(SUM(wr.wr_net_loss), 0) AS total_web_returns_loss,
        COUNT(DISTINCT p.p_promo_sk) AS promo_count,
        SUM(cs.cs_quantity) AS total_quantity_sold
    FROM item i
    JOIN inv_summary inv ON i.i_item_sk = inv.inv_item_sk
    JOIN catalog_sales cs ON i.i_item_sk = cs.cs_item_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                             AND cr.cr_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
                                 AND wr.wr_order_number = ws.ws_order_number
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_store_ret ON sr.sr_addr_sk = ca_store_ret.ca_address_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN customer_demographics cd_cs_bill ON cs.cs_bill_cdemo_sk = cd_cs_bill.cd_demo_sk
    JOIN household_demographics hd_cs_bill ON cs.cs_bill_hdemo_sk = hd_cs_bill.hd_demo_sk
    JOIN income_band ib ON hd_cs_bill.hd_income_band_sk = ib.ib_income_band_sk
    WHERE i.i_category = 'Electronics'
      AND i.i_current_price > 100
      AND w.w_state = 'CA'
      AND sm.sm_carrier = 'FEDEX'
      AND p.p_discount_active = 'Y'
      AND ca_bill.ca_state = 'TX'
    GROUP BY
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_category,
        i.i_current_price,
        inv.total_on_hand
    HAVING SUM(cs.cs_quantity) > 0
)
SELECT
    sa.i_item_id,
    sa.i_product_name,
    sa.i_category,
    sa.i_current_price,
    sa.total_on_hand,
    sa.total_sales_net_profit,
    sa.total_catalog_returns_loss,
    sa.total_store_returns_loss,
    sa.total_web_sales_net_profit,
    sa.total_web_returns_loss,
    sa.promo_count,
    sa.total_quantity_sold,
    (
        SELECT AVG(cs2.cs_net_profit)
        FROM catalog_sales cs2
        JOIN item i2 ON cs2.cs_item_sk = i2.i_item_sk
        WHERE i2.i_category = sa.i_category
    ) AS avg_category_net_profit,
    LAG(sa.total_sales_net_profit) OVER (ORDER BY sa.total_sales_net_profit DESC) AS prev_item_net_profit
FROM sales_agg sa
WHERE NOT EXISTS (
    SELECT 1
    FROM web_returns wr2
    WHERE wr2.wr_item_sk = sa.item_sk
)
ORDER BY sa.total_sales_net_profit DESC
LIMIT 100
