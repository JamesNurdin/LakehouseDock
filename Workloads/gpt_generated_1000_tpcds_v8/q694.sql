-- Goal: Compute profit metrics per physical store and per web site, combining store and web sales while filtering out stores with a specific return reason, excluding items that ever appeared in returns, and ranking the entities by net profit.

WITH base_store AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        i.i_item_sk,
        ss.ss_quantity,
        ss.ss_net_profit,
        CASE WHEN ss.ss_net_profit > 10000 THEN 'HIGH' ELSE 'LOW' END AS profit_category,
        td.t_hour,
        cd.cd_gender,
        ca.ca_state,
        r.r_reason_desc,
        inv.inv_quantity_on_hand
    FROM store_sales ss
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
    JOIN warehouse w ON inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE s.s_store_sk NOT IN (
        SELECT sr2.sr_store_sk
        FROM store_returns sr2
        WHERE sr2.sr_reason_sk IN (
            SELECT r2.r_reason_sk FROM reason r2 WHERE r2.r_reason_desc = 'Customer Returned'
        )
    )
),
agg_store AS (
    SELECT
        s_store_sk,
        s_store_name,
        COUNT(DISTINCT i_item_sk) AS distinct_items_sold,
        SUM(ss_quantity) AS total_qty_sold,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(CASE WHEN profit_category = 'HIGH' THEN ss_net_profit ELSE 0 END) AS high_profit_sum
    FROM base_store
    GROUP BY s_store_sk, s_store_name
),
item_excluding_returns AS (
    SELECT i_item_sk FROM item
    EXCEPT
    SELECT sr_item_sk FROM store_returns
),
store_set AS (
    SELECT s_store_sk FROM agg_store
),
web_agg AS (
    SELECT
        ws.ws_web_site_sk,
        ws_site.web_name,
        COUNT(DISTINCT ws.ws_item_sk) AS distinct_items_sold,
        SUM(ws.ws_quantity) AS total_qty_sold,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(CASE WHEN ws.ws_net_profit > 10000 THEN ws.ws_net_profit ELSE 0 END) AS high_profit_sum
    FROM web_sales ws
    JOIN time_dim td2 ON ws.ws_sold_time_sk = td2.t_time_sk
    JOIN item i2 ON ws.ws_item_sk = i2.i_item_sk
    JOIN customer_demographics cd2 ON ws.ws_bill_cdemo_sk = cd2.cd_demo_sk
    JOIN customer_address ca2 ON ws.ws_bill_addr_sk = ca2.ca_address_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site ws_site ON ws.ws_web_site_sk = ws_site.web_site_sk
    WHERE ws.ws_item_sk IN (SELECT i_item_sk FROM item_excluding_returns)
    GROUP BY ws.ws_web_site_sk, ws_site.web_name
)
SELECT
    entity_id,
    entity_name,
    entity_type,
    distinct_items_sold,
    total_qty_sold,
    total_net_profit,
    high_profit_sum,
    ROW_NUMBER() OVER (PARTITION BY entity_type ORDER BY total_net_profit DESC) AS rn
FROM (
    SELECT
        s_store_sk AS entity_id,
        s_store_name AS entity_name,
        'STORE' AS entity_type,
        distinct_items_sold,
        total_qty_sold,
        total_net_profit,
        high_profit_sum
    FROM agg_store
    WHERE s_store_sk IN (SELECT s_store_sk FROM store_set)
    UNION DISTINCT
    SELECT
        ws_web_site_sk AS entity_id,
        web_name AS entity_name,
        'WEB' AS entity_type,
        distinct_items_sold,
        total_qty_sold,
        total_net_profit,
        high_profit_sum
    FROM web_agg
) t
ORDER BY total_net_profit DESC
LIMIT 100
