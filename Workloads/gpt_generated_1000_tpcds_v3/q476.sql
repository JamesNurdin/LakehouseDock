WITH base AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        i.i_brand,
        i.i_current_price,
        s.s_state AS store_state,
        ca.ca_state AS address_state,
        w.w_state AS w_state,
        sm.sm_type AS sm_type,
        td.t_hour,
        cs.cs_net_profit,
        ss.ss_net_profit,
        ws.ws_net_profit,
        cr.cr_net_loss,
        sr.sr_net_loss,
        wr.wr_net_loss,
        r_sr.r_reason_desc AS store_return_reason,
        r_cr.r_reason_desc AS catalog_return_reason,
        cd.cd_gender,
        p.p_discount_active,
        inv.inv_quantity_on_hand
    FROM tpcds.item i
    JOIN tpcds.catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN tpcds.time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.store_sales ss ON ss.ss_item_sk = i.i_item_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN tpcds.warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.store_returns sr ON sr.sr_item_sk = ss.ss_item_sk
    JOIN tpcds.reason r_sr ON sr.sr_reason_sk = r_sr.r_reason_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_item_sk = i.i_item_sk
    JOIN tpcds.reason r_cr ON cr.cr_reason_sk = r_cr.r_reason_sk
    JOIN tpcds.web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN tpcds.web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
    JOIN tpcds.promotion p ON p.p_item_sk = i.i_item_sk
    JOIN tpcds.inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    JOIN tpcds.customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE 1 = 1
),
aggregated AS (
    SELECT
        i_category,
        i_brand,
        SUM(COALESCE(cs_net_profit, 0) + COALESCE(ss_net_profit, 0) + COALESCE(ws_net_profit, 0)) AS total_net_profit,
        AVG(COALESCE(cs_net_profit, 0) + COALESCE(ss_net_profit, 0) + COALESCE(ws_net_profit, 0)) AS avg_net_profit,
        COUNT(*) AS sales_cnt
    FROM base
    WHERE
        i_current_price > 100
        AND i_brand = 'Brand#12'
        AND store_state = 'CA'
        AND address_state = 'CA'
        AND w_state = 'CA'
        AND sm_type = 'AIR'
        AND t_hour BETWEEN 9 AND 17
        AND EXISTS (
            SELECT 1 FROM tpcds.promotion p2
            WHERE p2.p_item_sk = base.i_item_sk
              AND p2.p_discount_active = 'Y'
        )
    GROUP BY i_category, i_brand
    HAVING SUM(COALESCE(cs_net_profit, 0) + COALESCE(ss_net_profit, 0) + COALESCE(ws_net_profit, 0)) > 1000
)
SELECT
    i_category,
    i_brand,
    CASE WHEN total_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS profit_status,
    total_net_profit,
    avg_net_profit,
    sales_cnt,
    ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY total_net_profit DESC) AS category_rank,
    (SELECT AVG(total_net_profit) FROM aggregated) AS overall_avg_total_net_profit
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 100
