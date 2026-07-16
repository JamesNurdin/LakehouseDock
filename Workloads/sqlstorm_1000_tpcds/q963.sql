WITH
cc_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_division,
        COALESCE(SUM(cs.cs_net_profit), 0) AS cs_net_profit_sum,
        COALESCE(SUM(cs.cs_net_paid), 0) AS cs_net_paid_sum,
        COUNT(cs.cs_order_number) AS cs_order_cnt,
        MAX(cs.cs_sold_date_sk) AS cs_latest_sold_date_sk
    FROM call_center cc
    LEFT JOIN catalog_sales cs ON cc.cc_call_center_sk = cs.cs_call_center_sk
    GROUP BY cc.cc_call_center_sk, cc.cc_name, cc.cc_division
),
store_agg AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_division_id,
        COALESCE(SUM(ss.ss_net_profit), 0) AS ss_net_profit_sum,
        COALESCE(SUM(ss.ss_net_paid), 0) AS ss_net_paid_sum,
        COUNT(ss.ss_ticket_number) AS ss_order_cnt,
        MAX(ss.ss_sold_date_sk) AS ss_latest_sold_date_sk
    FROM store s
    LEFT JOIN store_sales ss ON s.s_store_sk = ss.ss_store_sk
    GROUP BY s.s_store_sk, s.s_store_name, s.s_division_id
),
combined AS (
    SELECT
        cc.cc_call_center_sk AS entity_id,
        cc.cc_name AS entity_name,
        cc.cc_division AS division_id,
        'Call Center' AS entity_type,
        cc.cs_net_profit_sum AS net_profit,
        cc.cs_net_paid_sum AS net_paid,
        cc.cs_order_cnt AS order_cnt,
        cc.cs_latest_sold_date_sk AS latest_sold_date_sk,
        (SELECT COALESCE(SUM(cr.cr_return_amount), 0) FROM catalog_returns cr WHERE cr.cr_call_center_sk = cc.cc_call_center_sk) AS total_return_amount
    FROM cc_agg cc
    UNION ALL
    SELECT
        s.s_store_sk AS entity_id,
        s.s_store_name AS entity_name,
        s.s_division_id AS division_id,
        'Store' AS entity_type,
        s.ss_net_profit_sum AS net_profit,
        s.ss_net_paid_sum AS net_paid,
        s.ss_order_cnt AS order_cnt,
        s.ss_latest_sold_date_sk AS latest_sold_date_sk,
        (SELECT COALESCE(SUM(sr.sr_net_loss), 0) FROM store_returns sr WHERE sr.sr_store_sk = s.s_store_sk) AS total_return_amount
    FROM store_agg s
),
promo_agg AS (
    SELECT
        cs.cs_call_center_sk AS cc_sk,
        COUNT(DISTINCT p.p_promo_sk) AS promo_cnt
    FROM catalog_sales cs
    JOIN promotion p ON cs.cs_item_sk = p.p_item_sk
    GROUP BY cs.cs_call_center_sk
)
SELECT
    COALESCE(c.entity_id, -1) AS entity_id,
    COALESCE(c.entity_name, 'PROMO_ONLY') AS entity_name,
    COALESCE(d.d_date, DATE '1900-01-01') AS latest_sold_date,
    COALESCE(c.entity_type, 'Promotion') AS entity_type,
    COALESCE(c.net_profit, 0) AS net_profit,
    COALESCE(c.net_paid, 0) AS net_paid,
    COALESCE(c.order_cnt, 0) AS order_cnt,
    COALESCE(c.total_return_amount, 0) AS total_return_amount,
    COALESCE(c.net_profit, 0) - COALESCE(c.total_return_amount, 0) AS net_profit_after_returns,
    CONCAT(COALESCE(c.entity_type, 'Promotion'), ' - ', COALESCE(c.entity_name, 'PROMO_ONLY')) AS report_line,
    CASE 
        WHEN COALESCE(c.net_profit, 0) > 1000000 THEN 'Platinum'
        WHEN COALESCE(c.net_profit, 0) > 500000 THEN 'Gold'
        WHEN COALESCE(c.net_profit, 0) > 100000 THEN 'Silver'
        ELSE 'Bronze'
    END AS profit_tier,
    CASE WHEN COALESCE(c.net_paid, 0) = 0 THEN NULL ELSE (COALESCE(c.net_profit, 0) / c.net_paid) * 100 END AS profit_margin_pct,
    COALESCE(c.division_id, -1) AS division_id,
    RANK() OVER (PARTITION BY COALESCE(c.division_id, -1) ORDER BY COALESCE(c.net_profit, 0) - COALESCE(c.total_return_amount, 0) DESC) AS division_rank,
    COALESCE(pa.promo_cnt, 0) AS promo_cnt
FROM combined c
FULL OUTER JOIN promo_agg pa ON c.entity_type = 'Call Center' AND c.entity_id = pa.cc_sk
LEFT JOIN date_dim d ON d.d_date_sk = c.latest_sold_date_sk
WHERE (COALESCE(c.net_profit, 0) - COALESCE(c.total_return_amount, 0)) > 0
ORDER BY division_id, division_rank
