WITH base AS (
   SELECT
        cr.cr_return_amount,
        cr.cr_order_number,
        cr.cr_return_quantity,
        i.i_item_id,
        i.i_category,
        w.w_warehouse_name,
        w.w_state,
        cc.cc_name,
        sm.sm_code,
        ca_refund.ca_city,
        ws.ws_quantity,
        ws.ws_net_profit,
        ws_site.web_name
   FROM catalog_returns cr
   JOIN item i ON cr.cr_item_sk = i.i_item_sk
   JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
   JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
   JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
   JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
   JOIN customer c_refund ON cr.cr_refunded_customer_sk = c_refund.c_customer_sk
   JOIN customer_address ca_refund ON cr.cr_refunded_addr_sk = ca_refund.ca_address_sk
   JOIN web_returns wr ON wr.wr_item_sk = i.i_item_sk
   JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
   JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
   WHERE cc.cc_state = 'CA'
     AND sm.sm_code IN ('SEA', 'AIR')
     AND ca_refund.ca_city = 'Lincoln'
     AND w.w_state = 'TX'
     AND cr.cr_return_amount > 1000
     AND ws.ws_quantity >= 10
),
agg AS (
   SELECT
        i_item_id,
        w_warehouse_name,
        web_name,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT cr_order_number) AS distinct_return_orders,
        ROW_NUMBER() OVER (PARTITION BY i_item_id ORDER BY SUM(ws_net_profit) DESC) AS profit_rank
   FROM base
   GROUP BY i_item_id, w_warehouse_name, web_name
)
SELECT DISTINCT
    a.i_item_id,
    a.w_warehouse_name,
    a.web_name,
    a.total_return_amount,
    a.total_net_profit,
    avg_ret.avg_return_amount
FROM agg a
JOIN (
    SELECT i_item_id, AVG(total_return_amount) AS avg_return_amount
    FROM agg
    GROUP BY i_item_id
) avg_ret ON a.i_item_id = avg_ret.i_item_id
WHERE a.total_net_profit > 2000
  AND avg_ret.avg_return_amount > 1500
  AND a.profit_rank = 1
ORDER BY a.total_net_profit DESC
LIMIT 100
