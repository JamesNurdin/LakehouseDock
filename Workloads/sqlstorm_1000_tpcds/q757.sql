WITH
cte_customer_sales AS (
    SELECT 
        c.c_customer_sk,
        COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS full_name,
        SUM(ss.ss_net_paid_inc_tax) AS total_store_sales,
        SUM(ws.ws_net_paid_inc_tax) AS total_web_sales,
        COUNT(DISTINCT ss.ss_ticket_number) AS cnt_store_orders,
        COUNT(DISTINCT ws.ws_order_number) AS cnt_web_orders,
        MAX(CASE WHEN ss.ss_net_profit > 0 THEN ss.ss_net_paid_inc_tax END) AS max_store_profit,
        MAX(CASE WHEN ws.ws_net_profit > 0 THEN ws.ws_net_paid_inc_tax END) AS max_web_profit,
        MIN(ss.ss_sold_date_sk) AS min_store_date,
        MIN(ws.ws_sold_date_sk) AS min_web_date
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    GROUP BY c.c_customer_sk, COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '')
),
call_center_agg AS (
    SELECT 
        cc.cc_call_center_sk,
        COUNT(*) AS cc_calls,
        SUM(cc.cc_gmt_offset) AS sum_gmt_offset
    FROM call_center cc
    GROUP BY cc.cc_call_center_sk
),
cte_ranked_customers AS (
    SELECT
        cs.*,
        CASE
            WHEN cs.total_store_sales > cs.total_web_sales THEN 'STORE'
            WHEN cs.total_store_sales < cs.total_web_sales THEN 'WEB'
            ELSE 'EQUAL'
        END AS dominant_channel,
        ROW_NUMBER() OVER (PARTITION BY cs.c_customer_sk ORDER BY GREATEST(cs.max_store_profit, cs.max_web_profit) DESC NULLS LAST) AS rnk
    FROM cte_customer_sales cs
),
cte_with_cc AS (
    SELECT
        rc.*,
        ca.cc_calls,
        ca.sum_gmt_offset
    FROM cte_ranked_customers rc
    LEFT JOIN call_center_agg ca
        ON (rc.c_customer_sk % 100) = (ca.cc_call_center_sk % 100)
)
SELECT
    wc.c_customer_sk,
    wc.full_name,
    wc.dominant_channel,
    wc.rnk,
    COALESCE(wc.total_store_sales / NULLIF(wc.cnt_store_orders, 0), 0) AS avg_store_order_value,
    COALESCE(wc.total_web_sales / NULLIF(wc.cnt_web_orders, 0), 0) AS avg_web_order_value,
    CASE 
        WHEN REGEXP_LIKE(wc.full_name, '^A.*') THEN 'StartsWithA' 
        ELSE 'Other' 
    END AS name_category,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_customer_sk = wc.c_customer_sk AND sr.sr_net_loss > 0) AS store_returns_with_loss,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_refunded_customer_sk = wc.c_customer_sk AND wr.wr_net_loss IS NOT NULL) AS web_returns_with_loss,
    GREATEST(COALESCE(wc.cnt_store_orders, 0), COALESCE(wc.cnt_web_orders, 0)) AS max_order_count,
    CASE
        WHEN wc.max_store_profit IS NULL AND wc.max_web_profit IS NULL THEN 'NO_PROFIT'
        WHEN wc.max_store_profit > wc.max_web_profit THEN 'STORE_PROFIT'
        WHEN wc.max_web_profit > wc.max_store_profit THEN 'WEB_PROFIT'
        ELSE 'EQUAL_PROFIT'
    END AS profit_leader,
    COALESCE(wc.cc_calls, 0) AS cc_calls,
    COALESCE(wc.sum_gmt_offset, 0) AS cc_sum_gmt_offset
FROM cte_with_cc wc
WHERE wc.rnk = 1
UNION ALL
SELECT
    -1 AS c_customer_sk,
    'Aggregated Summary' AS full_name,
    CASE WHEN SUM(total_store_sales) > SUM(total_web_sales) THEN 'STORE' ELSE 'WEB' END AS dominant_channel,
    NULL AS rnk,
    SUM(total_store_sales) / NULLIF(SUM(cnt_store_orders), 0) AS avg_store_order_value,
    SUM(total_web_sales) / NULLIF(SUM(cnt_web_orders), 0) AS avg_web_order_value,
    'SUMMARY' AS name_category,
    (SELECT COUNT(*) FROM store_returns sr WHERE sr.sr_return_quantity > 0) AS store_returns_with_loss,
    (SELECT COUNT(*) FROM web_returns wr WHERE wr.wr_return_quantity > 0) AS web_returns_with_loss,
    GREATEST(SUM(cnt_store_orders), SUM(cnt_web_orders)) AS max_order_count,
    CASE 
        WHEN SUM(max_store_profit) > SUM(max_web_profit) THEN 'STORE_PROFIT'
        WHEN SUM(max_web_profit) > SUM(max_store_profit) THEN 'WEB_PROFIT'
        ELSE 'EQUAL_PROFIT'
    END AS profit_leader,
    SUM(cc_calls) AS cc_calls,
    SUM(sum_gmt_offset) AS cc_sum_gmt_offset
FROM cte_with_cc
