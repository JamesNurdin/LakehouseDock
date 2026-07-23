WITH per_item AS (
    SELECT
        i.i_item_sk,
        i.i_item_id,
        i.i_product_name,
        i.i_current_price,
        SUM(cs.cs_net_profit) AS total_catalog_profit,
        SUM(ss.ss_net_profit) AS total_store_profit,
        SUM(ws.ws_net_profit) AS total_web_profit,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(cs.cs_net_profit + ss.ss_net_profit + ws.ws_net_profit - sr.sr_net_loss) AS total_combined_profit
    FROM item i
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
    JOIN promotion p ON p.p_item_sk = i.i_item_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk AND sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN customer cust ON cust.c_customer_sk = cs.cs_bill_customer_sk
    JOIN customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
    WHERE p.p_response_target > 10
      AND p.p_channel_tv = 'Y'
      AND p.p_discount_active = 'Y'
      AND cs.cs_ext_tax > 20.0
      AND cs.cs_ext_ship_cost < 2000.0
      AND inv.inv_quantity_on_hand > 500
      AND cc.cc_state = 'CA'
      AND i.i_current_price BETWEEN 100 AND 1000
      AND i.i_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
    GROUP BY i.i_item_sk, i.i_item_id, i.i_product_name, i.i_current_price
)
SELECT
    pi.i_item_id,
    pi.i_product_name,
    pi.i_current_price,
    pi.total_combined_profit,
    pi.total_catalog_profit,
    pi.total_store_profit,
    pi.total_web_profit,
    pi.total_return_loss,
    pi.total_combined_profit / pi.i_current_price AS profit_per_dollar
FROM per_item pi
WHERE pi.total_combined_profit > (
    SELECT AVG(total_combined_profit) FROM per_item
)
ORDER BY profit_per_dollar DESC
LIMIT 100
