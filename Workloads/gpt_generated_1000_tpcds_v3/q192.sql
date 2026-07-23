WITH sales_agg AS (
    SELECT
        cc.cc_call_center_id,
        i.i_category,
        t.t_hour,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        COUNT(*) AS num_sales,
        AVG(cs.cs_quantity) AS avg_quantity,
        MAX(cs.cs_sales_price) AS max_sales_price
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    JOIN store_returns sr ON sr.sr_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE
        cc.cc_country = 'United States'
        AND w.w_state = 'CA'
        AND i.i_category = 'Electronics'
        AND p.p_discount_active = 'Y'
        AND t.t_hour BETWEEN 9 AND 17
        AND cs.cs_quantity > 5
        AND cs.cs_sales_price > 100
    GROUP BY
        cc.cc_call_center_id,
        i.i_category,
        t.t_hour
)
SELECT
    s.cc_call_center_id,
    s.i_category,
    s.t_hour,
    s.total_net_profit,
    s.total_sales,
    s.num_sales,
    s.avg_quantity,
    s.max_sales_price,
    (SELECT AVG(total_net_profit) FROM sales_agg) AS overall_avg_net_profit,
    CASE
        WHEN s.total_net_profit > (SELECT AVG(total_net_profit) FROM sales_agg) THEN 'Above Avg'
        ELSE 'Below Avg'
    END AS profit_category
FROM sales_agg s
WHERE s.total_net_profit > (SELECT AVG(total_net_profit) FROM sales_agg) * 0.5
ORDER BY s.total_net_profit DESC
LIMIT 100
