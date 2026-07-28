WITH base AS (
    SELECT
        i.i_item_id,
        i.i_category AS i_category,
        s.s_state AS s_state,
        cs.cs_quantity,
        cs.cs_net_profit AS cs_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        sr.sr_net_loss AS sr_net_loss,
        p.p_channel_dmail,
        cp.cp_type,
        cc.cc_tax_percentage,
        sm.sm_type,
        inv.inv_quantity_on_hand
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    WHERE p.p_channel_dmail = 'Y'
      AND cp.cp_type = 'PROMO'
      AND cc.cc_tax_percentage > 5.00
      AND sm.sm_type IN ('AIR', 'RAIL')
      AND inv.inv_quantity_on_hand > 100
      AND NOT EXISTS (
          SELECT 1 FROM store_returns sr2
          WHERE sr2.sr_item_sk = i.i_item_sk
            AND sr2.sr_fee > 50
      )
),
agg AS (
    SELECT
        i_category,
        s_state,
        SUM(cs_quantity) AS total_quantity_sold,
        SUM(cs_net_profit + ws_net_profit - sr_net_loss) AS net_effect
    FROM base
    GROUP BY CUBE(i_category, s_state)
)
SELECT
    i_category,
    s_state,
    total_quantity_sold,
    net_effect,
    (SELECT AVG(net_effect) FROM agg) AS avg_net_effect
FROM agg
WHERE net_effect > (SELECT AVG(net_effect) FROM agg)
ORDER BY net_effect DESC
LIMIT 100
