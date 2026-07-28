WITH agg AS (
    SELECT
        s.s_state,
        p_ss.p_promo_name,
        SUM(ss.ss_net_paid) AS store_sales_net,
        SUM(ws.ws_net_paid) AS web_sales_net,
        SUM(cr.cr_return_amount) AS catalog_return_amount,
        GROUPING(s.s_state) AS grp_state,
        GROUPING(p_ss.p_promo_name) AS grp_promo
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p_ss ON ss.ss_promo_sk = p_ss.p_promo_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN promotion p_ws ON ws.ws_promo_sk = p_ws.p_promo_sk
    JOIN ship_mode sm_ws ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
    JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
    JOIN catalog_returns cr ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm_cr ON cr.cr_ship_mode_sk = sm_cr.sm_ship_mode_sk
    WHERE
        s.s_state = 'TX' AND
        cc.cc_country = 'United States' AND
        ca.ca_city IN ('Green', 'Hill 7th') AND
        sm_ws.sm_type = 'AIR' AND
        ss.ss_ext_tax > 20 AND
        ws.ws_net_paid > 1000 AND
        cr.cr_return_amount > 500
    GROUP BY GROUPING SETS (
        (s.s_state, p_ss.p_promo_name),
        (s.s_state),
        ()
    )
)
SELECT
    s_state,
    p_promo_name,
    store_sales_net,
    web_sales_net,
    catalog_return_amount,
    (SELECT avg(p_cost) FROM promotion) AS avg_promo_cost,
    RANK() OVER (
        ORDER BY (COALESCE(store_sales_net, 0) + COALESCE(web_sales_net, 0) - COALESCE(catalog_return_amount, 0)) DESC
    ) AS sales_rank,
    grp_state,
    grp_promo
FROM agg
ORDER BY sales_rank, s_state, p_promo_name
LIMIT 100
