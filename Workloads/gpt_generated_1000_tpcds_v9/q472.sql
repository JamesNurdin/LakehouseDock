/* Goal: Analyze net profit and return performance by item category across store and catalog channels, ranking categories by profit and showing detailed per‑item return totals. */
WITH
store_agg AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        s.s_state AS grouping_attribute,
        SUM(ss.ss_net_profit) AS net_metric,
        COALESCE(SUM(sr.sr_return_amt), 0) AS return_metric,
        COUNT(DISTINCT ss.ss_ticket_number) AS order_cnt,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        'store' AS source
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    LEFT JOIN store_returns sr
        ON ss.ss_ticket_number = sr.sr_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    WHERE
        i.i_current_price BETWEEN 50 AND 200
        AND s.s_state = 'CA'
        AND p.p_discount_active = 'Y'
        AND cd.cd_gender = 'M'
        AND hd.hd_buy_potential = '501-1000'
        AND EXISTS (
            SELECT 1
            FROM web_page wp
            WHERE wp.wp_customer_sk = c.c_customer_sk
              AND wp.wp_autogen_flag = 'Y'
        )
    GROUP BY i.i_item_sk, i.i_category, s.s_state
),
catalog_agg AS (
    SELECT
        i.i_item_sk,
        i.i_category,
        cc.cc_class AS grouping_attribute,
        SUM(cs.cs_net_paid) AS net_metric,
        COALESCE(SUM(cr.cr_return_amount), 0) AS return_metric,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        'catalog' AS source
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    WHERE
        cc.cc_class = 'medium'
        AND cc.cc_tax_percentage = 0.06
        AND i.i_color = 'Red'
        AND sm.sm_type = 'AIR'
        AND p.p_discount_active = 'Y'
        AND i.i_size = 'M'
    GROUP BY i.i_item_sk, i.i_category, cc.cc_class
),
combined AS (
    SELECT i_item_sk, i_category, grouping_attribute, net_metric, return_metric, order_cnt, avg_discount, source
    FROM store_agg
    UNION ALL
    SELECT i_item_sk, i_category, grouping_attribute, net_metric, return_metric, order_cnt, avg_discount, source
    FROM catalog_agg
)
SELECT
    ca.i_item_sk,
    ca.i_category,
    ca.grouping_attribute,
    ca.source,
    ca.net_metric,
    ca.return_metric,
    ca.order_cnt,
    ca.avg_discount,
    (SELECT COALESCE(SUM(cr2.cr_return_amount), 0) FROM catalog_returns cr2 WHERE cr2.cr_item_sk = ca.i_item_sk) AS total_catalog_return_amount,
    (SELECT COALESCE(SUM(sr2.sr_return_amt), 0) FROM store_returns sr2 WHERE sr2.sr_item_sk = ca.i_item_sk) AS total_store_return_amount,
    (SELECT COALESCE(SUM(wr2.wr_return_amt), 0) FROM web_returns wr2 WHERE wr2.wr_item_sk = ca.i_item_sk) AS total_web_return_amount,
    ROW_NUMBER() OVER (PARTITION BY ca.i_category ORDER BY ca.net_metric DESC) AS category_rank
FROM combined ca
WHERE ca.net_metric > 0
ORDER BY ca.i_category, category_rank
LIMIT 100
