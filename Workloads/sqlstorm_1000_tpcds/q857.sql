WITH date_range AS (
    SELECT d_date_sk
    FROM date_dim
    WHERE d_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
),
store_sales_data AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_state,
        d.d_year,
        SUM(COALESCE(ss.ss_net_paid, 0)) AS total_net_paid,
        SUM(COALESCE(ss.ss_net_profit, 0)) AS total_net_profit,
        COUNT(ss.ss_ticket_number) AS transaction_count,
        AVG(ss.ss_quantity) AS avg_quantity,
        MAX(ss.ss_sales_price) AS max_sales_price,
        MIN(ss.ss_sales_price) AS min_sales_price,
        COUNT(DISTINCT sr.sr_ticket_number) AS return_ticket_cnt,
        COALESCE(SUM(sr.sr_net_loss), 0) AS total_return_loss
    FROM store s
    LEFT JOIN store_sales ss
        ON s.s_store_sk = ss.ss_store_sk
       AND ss.ss_sold_date_sk IN (SELECT d_date_sk FROM date_range)
    LEFT JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    LEFT JOIN store_returns sr
        ON ss.ss_store_sk = sr.sr_store_sk
       AND ss.ss_item_sk = sr.sr_item_sk
       AND ss.ss_ticket_number = sr.sr_ticket_number
    GROUP BY s.s_store_sk, s.s_store_name, s.s_state, d.d_year
),
store_ranking AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_state,
        d_year,
        total_net_paid,
        total_net_profit,
        transaction_count,
        avg_quantity,
        max_sales_price,
        min_sales_price,
        return_ticket_cnt,
        total_return_loss,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank,
        RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS paid_rank
    FROM store_sales_data
),
store_top AS (
    SELECT *
    FROM store_ranking
    WHERE profit_rank <= 5
),
call_center_sales AS (
    SELECT 
        cc.cc_call_center_sk,
        CONCAT(cc.cc_name, ' - ', cc.cc_city) AS cc_full_name,
        d.d_year,
        COALESCE(SUM(cs.cs_net_paid), 0) AS total_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        COALESCE(SUM(CASE WHEN cs.cs_net_profit > 0 THEN cs.cs_net_profit ELSE 0 END), 0) AS profit_sum
    FROM call_center cc
    LEFT JOIN catalog_sales cs
        ON cc.cc_call_center_sk = cs.cs_call_center_sk
       AND cs.cs_sold_date_sk IN (SELECT d_date_sk FROM date_range)
    LEFT JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    GROUP BY cc.cc_call_center_sk, CONCAT(cc.cc_name, ' - ', cc.cc_city), d.d_year
),
union_entities AS (
    SELECT
        s.s_store_sk AS entity_sk,
        s.s_store_name AS entity_name,
        s.s_state AS entity_state,
        s.d_year AS year,
        s.total_net_paid,
        s.total_net_profit,
        s.transaction_count,
        s.avg_quantity,
        s.max_sales_price,
        s.min_sales_price,
        s.return_ticket_cnt,
        s.total_return_loss,
        s.profit_rank,
        s.paid_rank,
        NULL AS cc_total_net_paid,
        NULL AS cc_order_cnt,
        'store' AS entity_type
    FROM store_top s

    UNION ALL

    SELECT
        cc.cc_call_center_sk AS entity_sk,
        cc.cc_full_name AS entity_name,
        NULL AS entity_state,
        cc.d_year AS year,
        cc.total_net_paid,
        NULL AS total_net_profit,
        NULL AS transaction_count,
        NULL AS avg_quantity,
        NULL AS max_sales_price,
        NULL AS min_sales_price,
        NULL AS return_ticket_cnt,
        NULL AS total_return_loss,
        NULL AS profit_rank,
        NULL AS paid_rank,
        cc.total_net_paid AS cc_total_net_paid,
        cc.order_cnt AS cc_order_cnt,
        'call_center' AS entity_type
    FROM call_center_sales cc
),
final_result AS (
    SELECT 
        ue.entity_type,
        ue.entity_sk,
        ue.entity_name,
        ue.entity_state,
        ue.year,
        COALESCE(ue.total_net_paid, 0) AS total_net_paid,
        COALESCE(ue.total_net_profit, 0) AS total_net_profit,
        COALESCE(ue.transaction_count, 0) AS transaction_count,
        COALESCE(ue.avg_quantity, 0) AS avg_quantity,
        COALESCE(ue.max_sales_price, 0) AS max_sales_price,
        COALESCE(ue.min_sales_price, 0) AS min_sales_price,
        COALESCE(ue.return_ticket_cnt, 0) AS return_ticket_cnt,
        COALESCE(ue.total_return_loss, 0) AS total_return_loss,
        ue.profit_rank,
        ue.paid_rank,
        COALESCE(ue.cc_total_net_paid, 0) AS cc_total_net_paid,
        COALESCE(ue.cc_order_cnt, 0) AS cc_order_cnt,
        (SELECT AVG(s2.total_net_profit)
         FROM store_sales_data s2
         WHERE s2.s_state = ue.entity_state
           AND s2.d_year = ue.year) AS avg_state_profit,
        (SELECT COUNT(DISTINCT sr2.sr_reason_sk)
         FROM store_returns sr2
         WHERE sr2.sr_store_sk = ue.entity_sk) AS distinct_return_reasons,
        CONCAT(ue.entity_name, ' [', CASE WHEN ue.entity_type = 'store' THEN 'Store' ELSE 'Call Center' END, ']') AS display_name,
        substr(ue.entity_name, 1, 15) AS short_name,
        length(ue.entity_name) AS name_length,
        upper(ue.entity_name) AS entity_name_upper,
        CASE 
            WHEN ue.entity_type = 'store' AND ue.total_net_profit > 0 AND ue.return_ticket_cnt = 0 THEN 'PROFIT_NO_RETURNS'
            WHEN ue.entity_type = 'store' AND ue.total_net_profit < 0 THEN 'LOSS'
            WHEN ue.entity_type = 'call_center' AND ue.cc_total_net_paid > 500000 THEN 'HIGH_VOLUME'
            ELSE 'OTHER'
        END AS performance_category,
        SUM(COALESCE(ue.total_net_paid, 0)) OVER (PARTITION BY ue.entity_type ORDER BY ue.year) AS cumulative_net_paid,
        LAG(COALESCE(ue.total_net_paid, 0)) OVER (PARTITION BY ue.entity_type ORDER BY ue.year) AS prev_year_net_paid
    FROM union_entities ue
)

SELECT *
FROM final_result
WHERE (entity_type = 'store' AND profit_rank <= 3 AND total_return_loss < 1000)
   OR (entity_type = 'call_center' AND cc_order_cnt > 100 AND (cc_total_net_paid / NULLIF(cc_order_cnt, 0)) > 5000)
ORDER BY entity_type, year DESC NULLS LAST, profit_rank NULLS LAST
LIMIT 200
