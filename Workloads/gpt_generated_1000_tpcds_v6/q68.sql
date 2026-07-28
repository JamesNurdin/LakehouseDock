WITH base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_item_sk,
        cs.cs_quantity AS cs_quantity,
        cs.cs_net_profit AS cs_net_profit,
        cs.cs_promo_sk,
        i.i_item_id,
        p.p_promo_name,
        c.c_customer_id,
        ca.ca_country,
        sm.sm_carrier,
        w.w_warehouse_name,
        ss.ss_ticket_number,
        ss.ss_quantity AS ss_quantity,
        ss.ss_net_profit AS ss_net_profit,
        s.s_store_name,
        inv.inv_quantity_on_hand,
        ws.ws_order_number,
        ws.ws_quantity AS ws_quantity,
        ws.ws_net_profit AS ws_net_profit,
        web.web_name,
        td.t_hour
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    LEFT JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    LEFT JOIN store_sales ss ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_site web ON ws.ws_web_site_sk = web.web_site_sk
    WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
      AND i.i_rec_start_date <= DATE '2002-12-31'
      AND web.web_rec_start_date >= DATE '2001-01-01'
      AND ca.ca_country = 'United States'
      AND sm.sm_carrier = 'BOXBUNDLES'
),
agg AS (
    SELECT
        i_item_id,
        p_promo_name,
        SUM(cs_net_profit) AS cs_profit,
        SUM(ss_net_profit) AS ss_profit,
        SUM(ws_net_profit) AS ws_profit,
        COUNT(DISTINCT cs_order_number) AS cs_orders,
        COUNT(DISTINCT ss_ticket_number) AS ss_tickets,
        COUNT(DISTINCT ws_order_number) AS ws_orders,
        SUM(cs_quantity) + SUM(ss_quantity) + SUM(ws_quantity) AS total_quantity,
        CASE WHEN (SUM(cs_quantity) + SUM(ss_quantity) + SUM(ws_quantity)) > 1000 THEN 'HIGH' ELSE 'LOW' END AS volume_category
    FROM base
    GROUP BY i_item_id, p_promo_name
)
SELECT
    i_item_id,
    p_promo_name,
    cs_profit,
    ss_profit,
    ws_profit,
    cs_orders,
    ss_tickets,
    ws_orders,
    volume_category,
    (cs_profit + ss_profit + ws_profit) / NULLIF(cs_orders + ss_tickets + ws_orders, 0) AS avg_profit_per_transaction,
    ROW_NUMBER() OVER (PARTITION BY volume_category ORDER BY (cs_profit + ss_profit + ws_profit) DESC) AS rank_within_volume
FROM agg
WHERE (cs_profit + ss_profit + ws_profit) > 10000
  AND volume_category = 'HIGH'
ORDER BY avg_profit_per_transaction DESC
LIMIT 100
