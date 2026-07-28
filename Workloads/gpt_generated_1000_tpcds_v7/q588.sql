WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        sm.sm_ship_mode_id,
        SUM(cs.cs_net_profit)                 AS catalog_profit,
        SUM(cs.cs_net_paid)                   AS catalog_paid,
        SUM(cr.cr_net_loss)                   AS catalog_return_loss,
        SUM(ws.ws_net_profit)                 AS web_profit,
        SUM(ws.ws_net_paid)                   AS web_paid,
        SUM(wr.wr_net_loss)                   AS web_return_loss,
        COUNT(*)                              AS txn_count
    FROM call_center cc
    JOIN catalog_sales cs
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim td
      ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN ship_mode sm
      ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
      ON cs.cs_promo_sk = p.p_promo_sk
    JOIN customer_address ca
      ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
      ON cr.cr_order_number = cs.cs_order_number
     AND cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws
      ON ws.ws_sold_time_sk = td.t_time_sk
     AND ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp
      ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we
      ON ws.ws_web_site_sk = we.web_site_sk
    LEFT JOIN web_returns wr
      ON wr.wr_order_number = ws.ws_order_number
     AND wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE td.t_hour BETWEEN 6 AND 18
      AND p.p_discount_active = 'Y'
      AND cs.cs_sales_price > 50
    GROUP BY cc.cc_call_center_id, sm.sm_ship_mode_id
)
SELECT
    cc_id,
    AVG(total_profit)   AS avg_profit_per_ship_mode,
    SUM(total_txn)      AS total_transactions
FROM (
    SELECT
        cc_call_center_id AS cc_id,
        (catalog_profit + web_profit - catalog_return_loss - web_return_loss) AS total_profit,
        txn_count AS total_txn
    FROM sales_agg
) agg
GROUP BY cc_id
HAVING AVG(total_profit) > 1000
ORDER BY avg_profit_per_ship_mode DESC
LIMIT 100
