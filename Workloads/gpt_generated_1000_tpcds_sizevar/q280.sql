WITH ticket_intersect AS (
    SELECT ss_ticket_number
    FROM store_sales
    WHERE ss_quantity > 5
    INTERSECT
    SELECT ws_order_number
    FROM web_sales
    WHERE ws_quantity > 5
),
ws_daily AS (
    SELECT ws_sold_date_sk,
           SUM(ws_net_profit) AS daily_web_profit
    FROM web_sales
    GROUP BY ws_sold_date_sk
),
inv_daily AS (
    SELECT inv_date_sk,
           inv_warehouse_sk,
           SUM(inv_quantity_on_hand) AS daily_on_hand
    FROM inventory
    GROUP BY inv_date_sk, inv_warehouse_sk
),
base AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_net_profit,
        ss.ss_quantity,
        d.d_year,
        s.s_store_name,
        s.s_state,
        p.p_promo_name,
        ca.ca_state AS ca_state,
        ca.ca_gmt_offset,
        cr.cr_return_amount,
        sr.sr_net_loss,
        ws_daily.daily_web_profit,
        inv_daily.daily_on_hand,
        w.w_warehouse_name,
        w.w_state,
        sm.sm_type,
        cc.cc_name,
        cp.cp_department
    FROM date_dim d
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_refunded_addr_sk = ca.ca_address_sk
    LEFT JOIN ws_daily ON ws_daily.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN inv_daily ON inv_daily.inv_date_sk = d.d_date_sk
    LEFT JOIN warehouse w ON inv_daily.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN ship_mode sm ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND p.p_discount_active = 'Y'
      AND ca.ca_gmt_offset > 0
      AND w.w_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND ss.ss_net_profit > 0
      AND ss.ss_ticket_number IN (SELECT ss_ticket_number FROM ticket_intersect)
      AND ss.ss_quantity > 2
      AND cr.cr_return_amount IS NOT NULL
),
agg AS (
    SELECT
        s_store_name,
        p_promo_name,
        SUM(ss_net_profit) AS total_store_profit,
        SUM(COALESCE(daily_web_profit, 0)) AS total_web_profit,
        SUM(COALESCE(cr_return_amount, 0)) AS total_return_amount,
        SUM(COALESCE(sr_net_loss, 0)) AS total_return_loss,
        SUM(COALESCE(daily_on_hand, 0)) AS total_on_hand,
        COUNT(*) AS txn_count,
        AVG(ss_quantity) AS avg_quantity
    FROM base
    GROUP BY s_store_name, p_promo_name
),
final AS (
    SELECT
        a.s_store_name,
        a.p_promo_name,
        a.total_store_profit,
        a.total_web_profit,
        a.total_return_amount,
        a.total_return_loss,
        a.total_on_hand,
        a.txn_count,
        a.avg_quantity,
        (SELECT AVG(total_store_profit) FROM agg) AS avg_store_profit
    FROM agg a
    WHERE a.total_store_profit > (SELECT AVG(total_store_profit) FROM agg)
      AND a.txn_count >= 10
      AND a.avg_quantity > 1
      AND a.total_return_amount > 1000
      AND a.total_on_hand > 5000
)
SELECT *
FROM final
ORDER BY total_store_profit DESC
LIMIT 100
