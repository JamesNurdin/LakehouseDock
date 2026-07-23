WITH cs_agg AS (
    SELECT
        cs_item_sk,
        cs_call_center_sk,
        cs_ship_mode_sk,
        SUM(cs_net_paid) AS cs_total_net_paid,
        SUM(cs_net_profit) AS cs_total_net_profit,
        SUM(cs_quantity) AS cs_total_quantity
    FROM catalog_sales
    GROUP BY cs_item_sk, cs_call_center_sk, cs_ship_mode_sk
)
SELECT
    i.i_category,
    i.i_class,
    cc.cc_name,
    sm_cs.sm_type,
    s.s_store_name,
    wp.wp_type,
    SUM(COALESCE(cs_agg.cs_total_net_paid, 0) + COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_net_paid,
    SUM(COALESCE(cs_agg.cs_total_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(wr.wr_return_amt, 0)) AS net_profit,
    CASE
        WHEN SUM(COALESCE(cs_agg.cs_total_net_paid, 0) + COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) > 0
        THEN SUM(COALESCE(cs_agg.cs_total_net_profit, 0) + COALESCE(ss.ss_net_profit, 0) + COALESCE(ws.ws_net_profit, 0) - COALESCE(wr.wr_return_amt, 0))
             / SUM(COALESCE(cs_agg.cs_total_net_paid, 0) + COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0))
        ELSE 0
    END AS profit_margin,
    COUNT(DISTINCT c_ss.c_customer_sk) AS distinct_customers
FROM cs_agg
JOIN item i
    ON cs_agg.cs_item_sk = i.i_item_sk
JOIN call_center cc
    ON cs_agg.cs_call_center_sk = cc.cc_call_center_sk
JOIN ship_mode sm_cs
    ON cs_agg.cs_ship_mode_sk = sm_cs.sm_ship_mode_sk
LEFT JOIN store_sales ss
    ON ss.ss_item_sk = i.i_item_sk
LEFT JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
LEFT JOIN customer c_ss
    ON ss.ss_customer_sk = c_ss.c_customer_sk
LEFT JOIN customer_address ca_ss
    ON ss.ss_addr_sk = ca_ss.ca_address_sk
LEFT JOIN customer_demographics cd_ss
    ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
LEFT JOIN household_demographics hd_ss
    ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
LEFT JOIN web_sales ws
    ON ws.ws_item_sk = i.i_item_sk
LEFT JOIN ship_mode sm_ws
    ON ws.ws_ship_mode_sk = sm_ws.sm_ship_mode_sk
LEFT JOIN web_page wp
    ON ws.ws_web_page_sk = wp.wp_web_page_sk
LEFT JOIN web_returns wr
    ON wr.wr_order_number = ws.ws_order_number
    AND wr.wr_item_sk = i.i_item_sk
    AND wr.wr_web_page_sk = wp.wp_web_page_sk
LEFT JOIN customer c_ws
    ON ws.ws_bill_customer_sk = c_ws.c_customer_sk
LEFT JOIN customer_address ca_ws
    ON ws.ws_bill_addr_sk = ca_ws.ca_address_sk
LEFT JOIN customer_demographics cd_ws
    ON ws.ws_bill_cdemo_sk = cd_ws.cd_demo_sk
LEFT JOIN household_demographics hd_ws
    ON ws.ws_bill_hdemo_sk = hd_ws.hd_demo_sk
WHERE
    cc.cc_rec_start_date >= DATE '2000-01-01'
    AND cc.cc_rec_end_date <= DATE '2005-12-31'
    AND i.i_rec_start_date >= DATE '1999-01-01'
    AND i.i_rec_end_date <= DATE '2002-12-31'
    AND s.s_zip = '61933'
    AND ca_ss.ca_state = 'CA'
    AND wp.wp_image_count >= 3
    AND c_ss.c_preferred_cust_flag = 'Y'
GROUP BY
    i.i_category,
    i.i_class,
    cc.cc_name,
    sm_cs.sm_type,
    s.s_store_name,
    wp.wp_type
HAVING
    SUM(COALESCE(cs_agg.cs_total_net_paid, 0) + COALESCE(ss.ss_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) > 10000
ORDER BY
    total_net_paid DESC
LIMIT 100
