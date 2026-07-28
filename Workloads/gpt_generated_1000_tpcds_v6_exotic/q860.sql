WITH sales_agg AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        SUM(cs.cs_net_profit) AS cat_cs_profit,
        SUM(ws.ws_net_profit) AS cat_ws_profit,
        COUNT(DISTINCT cs.cs_order_number) AS cs_orders,
        COUNT(DISTINCT ws.ws_order_number) AS ws_orders
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd_bill ON cs.cs_bill_cdemo_sk = cd_bill.cd_demo_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE cp.cp_department = 'Electronics'
      AND p.p_discount_active = 'Y'
      AND i.i_category_id IN (1, 2, 3)
      AND i.i_brand IN ('BrandA', 'BrandB')
    GROUP BY i.i_item_sk, i.i_category
    HAVING SUM(cs.cs_net_profit) > 1000
),
returns_agg AS (
    SELECT
        i.i_item_sk,
        SUM(sr.sr_net_loss) AS total_sr_loss,
        SUM(wr.wr_net_loss) AS total_wr_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS sr_returns,
        COUNT(DISTINCT wr.wr_return_quantity) AS wr_returns
    FROM item i
    LEFT JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    LEFT JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
    WHERE s.s_manager IN ('Ricky Nichols', 'William Ward')
      AND sr.sr_return_quantity > 0
    GROUP BY i.i_item_sk
)
SELECT
    sa.i_category,
    COUNT(DISTINCT sa.i_item_sk) AS num_items,
    SUM(sa.cat_cs_profit + sa.cat_ws_profit) AS total_profit,
    SUM(ra.total_sr_loss + ra.total_wr_loss) AS total_loss,
    (SUM(sa.cat_cs_profit + sa.cat_ws_profit) - SUM(ra.total_sr_loss + ra.total_wr_loss)) / NULLIF(COUNT(DISTINCT sa.i_item_sk), 0) AS avg_net_per_item,
    ROW_NUMBER() OVER (ORDER BY SUM(sa.cat_cs_profit + sa.cat_ws_profit) DESC) AS rank_by_profit,
    (SELECT SUM(ws.ws_net_paid) FROM web_sales ws) AS total_ws_net_paid,
    (SELECT SUM(cs.cs_net_paid) FROM catalog_sales cs) AS total_cs_net_paid
FROM sales_agg sa
JOIN returns_agg ra ON ra.i_item_sk = sa.i_item_sk
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr2
    JOIN store s2 ON sr2.sr_store_sk = s2.s_store_sk
    WHERE sr2.sr_item_sk = sa.i_item_sk
      AND s2.s_state = 'CA'
)
GROUP BY sa.i_category
HAVING SUM(sa.cat_cs_profit + sa.cat_ws_profit) > 5000
ORDER BY avg_net_per_item DESC
LIMIT 100
