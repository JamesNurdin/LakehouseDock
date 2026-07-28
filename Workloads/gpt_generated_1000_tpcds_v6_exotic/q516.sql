WITH sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_manager,
        hd.hd_buy_potential,
        SUM(ss.ss_ext_sales_price) AS total_ext_sales,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS txn_count,
        CASE
            WHEN SUM(ss.ss_net_profit) > 10000 THEN 'HIGH'
            ELSE 'LOW'
        END AS profit_category
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    WHERE s.s_manager IN ('Scott Mclaughlin', 'David Thomas')
      AND hd.hd_buy_potential IN ('501-1000', '>10000')
      AND ss.ss_net_paid_inc_tax > 1000
      AND s.s_state = 'CA'
    GROUP BY s.s_store_id, s.s_manager, hd.hd_buy_potential
),
web_agg AS (
    SELECT
        hd.hd_buy_potential,
        ws.ws_web_page_sk,
        wp.wp_type,
        SUM(ws.ws_ext_sales_price) AS web_ext_sales,
        COUNT(*) AS web_txn
    FROM web_sales ws
    JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_type = 'Content'
      AND ws.ws_net_paid_inc_tax > 500
      AND hd.hd_dep_count >= 1
      AND ws.ws_quantity > 0
    GROUP BY hd.hd_buy_potential, ws.ws_web_page_sk, wp.wp_type
)
SELECT
    sa.profit_category,
    AVG(sa.total_ext_sales) AS avg_store_sales,
    SUM(wa.web_ext_sales) AS total_web_sales,
    COUNT(*) AS store_hd_groups
FROM sales_agg sa
LEFT JOIN web_agg wa ON sa.hd_buy_potential = wa.hd_buy_potential
GROUP BY sa.profit_category
ORDER BY avg_store_sales DESC
LIMIT 100
