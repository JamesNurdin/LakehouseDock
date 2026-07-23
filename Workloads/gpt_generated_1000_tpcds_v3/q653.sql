WITH agg AS (
    SELECT
        p.p_promo_id,
        t.t_hour,
        w.w_warehouse_name,
        cc.cc_division,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_net_profit) AS web_profit,
        SUM(cr.cr_net_loss) AS return_loss,
        (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) AS total_profit
    FROM
        catalog_sales cs
        INNER JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
        INNER JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
        INNER JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        INNER JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        INNER JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
        INNER JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        INNER JOIN store_sales ss ON ss.ss_sold_time_sk = t.t_time_sk
            AND ss.ss_hdemo_sk = hd.hd_demo_sk
            AND ss.ss_promo_sk = p.p_promo_sk
        INNER JOIN web_sales ws ON ws.ws_sold_time_sk = t.t_time_sk
            AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
            AND ws.ws_ship_hdemo_sk = hd.hd_demo_sk
            AND ws.ws_promo_sk = p.p_promo_sk
            AND ws.ws_warehouse_sk = w.w_warehouse_sk
        INNER JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
        INNER JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
        LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
            AND cr.cr_item_sk = cs.cs_item_sk
            AND cr.cr_returned_time_sk = t.t_time_sk
            AND cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
            AND cr.cr_call_center_sk = cc.cc_call_center_sk
            AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
            AND cr.cr_warehouse_sk = w.w_warehouse_sk
        LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE
        cc.cc_division = 3
        AND p.p_discount_active = 'Y'
        AND hd.hd_buy_potential = '501-1000'
        AND w.w_state = 'CA'
        AND t.t_hour BETWEEN 9 AND 17
        AND cp.cp_catalog_number > 10
    GROUP BY
        p.p_promo_id,
        t.t_hour,
        w.w_warehouse_name,
        cc.cc_division
    HAVING
        (SUM(cs.cs_net_profit) + SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit)) > 100000
)
SELECT
    p_promo_id,
    t_hour,
    w_warehouse_name,
    cc_division,
    catalog_profit,
    store_profit,
    web_profit,
    return_loss,
    total_profit,
    RANK() OVER (PARTITION BY t_hour ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank, p_promo_id
LIMIT 100
