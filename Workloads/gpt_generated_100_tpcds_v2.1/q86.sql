WITH base_data AS (
    SELECT
        d.d_date,
        d.d_date_sk,
        d.d_year,
        d.d_weekend,
        w.w_warehouse_name,
        w.w_country,
        p.p_promo_name,
        p.p_discount_active,
        cc.cc_state,
        cc.cc_name,
        cp.cp_type,
        sm.sm_type,
        r.r_reason_desc,
        wp.wp_type,
        hd.hd_buy_potential,
        ss.ss_net_profit AS ss_net_profit,
        ws.ws_net_profit AS ws_net_profit,
        sr.sr_net_loss AS sr_net_loss,
        wr.wr_net_loss AS wr_net_loss,
        cr.cr_net_loss AS cr_net_loss,
        i.inv_quantity_on_hand AS inv_quantity_on_hand,
        ss.ss_ticket_number,
        ws.ws_order_number,
        t.t_hour
    FROM date_dim d
    LEFT JOIN store_sales ss
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    LEFT JOIN time_dim t
        ON ss.ss_sold_time_sk = t.t_time_sk
    LEFT JOIN web_sales ws
        ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_date_sk = d.d_date_sk
    LEFT JOIN call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    LEFT JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    LEFT JOIN ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    LEFT JOIN reason r
        ON r.r_reason_sk = sr.sr_reason_sk
        OR r.r_reason_sk = cr.cr_reason_sk
        OR r.r_reason_sk = wr.wr_reason_sk
    LEFT JOIN warehouse w
        ON w.w_warehouse_sk = ws.ws_warehouse_sk
        AND w.w_warehouse_sk = cr.cr_warehouse_sk
    LEFT JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
        AND i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        d.d_year BETWEEN 2000 AND 2002
        AND w.w_country = 'United States'
        AND p.p_discount_active = 'Y'
        AND cc.cc_state = 'CA'
        AND r.r_reason_desc LIKE '%size%'
        AND d.d_weekend = 'N'
        AND t.t_hour BETWEEN 9 AND 17
        AND EXISTS (
            SELECT 1
            FROM catalog_page cp2
            WHERE cp2.cp_catalog_page_sk = cr.cr_catalog_page_sk
              AND cp2.cp_type = 'Electronics'
        )
), agg_data AS (
    SELECT
        d_date,
        d_date_sk,
        w_warehouse_name,
        p_promo_name,
        SUM(ss_net_profit) AS store_profit,
        SUM(ws_net_profit) AS web_profit,
        SUM(COALESCE(sr_net_loss, 0)) AS store_return_loss,
        SUM(COALESCE(wr_net_loss, 0)) AS web_return_loss,
        SUM(COALESCE(cr_net_loss, 0)) AS catalog_return_loss,
        SUM(inv_quantity_on_hand) AS inventory_qty,
        COUNT(DISTINCT ss_ticket_number) AS distinct_store_sales,
        COUNT(DISTINCT ws_order_number) AS distinct_web_sales
    FROM base_data
    GROUP BY
        d_date,
        d_date_sk,
        w_warehouse_name,
        p_promo_name
)
SELECT
    d_date,
    w_warehouse_name,
    p_promo_name,
    store_profit,
    web_profit,
    store_return_loss,
    web_return_loss,
    catalog_return_loss,
    inventory_qty,
    distinct_store_sales,
    distinct_web_sales,
    ROW_NUMBER() OVER (PARTITION BY d_date ORDER BY (store_profit + web_profit) DESC) AS warehouse_daily_rank,
    RANK() OVER (ORDER BY (store_profit + web_profit) DESC) AS overall_warehouse_profit_rank,
    CASE
        WHEN (store_profit + web_profit) > 1000000 THEN 'High'
        WHEN (store_profit + web_profit) > 500000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_sold_date_sk = agg_data.d_date_sk) AS total_store_sales_on_date
FROM agg_data
ORDER BY overall_warehouse_profit_rank
LIMIT 100
