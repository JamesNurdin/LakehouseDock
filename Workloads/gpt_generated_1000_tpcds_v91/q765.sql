/*
Goal: Produce per‑item aggregated sales and return metrics for items that have both sales and returns. The query joins all five TPC‑DS tables using the allowed keys, re‑uses dimensions under different aliases, pre‑aggregates sales and returns, combines sales and return rows via UNION ALL, filters to items present in both sets using INTERSECT, adds CASE logic for profit/return flags, groups the results, orders by the combined metric and limits to the top 100 rows.
*/
WITH
-- Aggregate store sales per item, household, and sold time
sales_agg AS (
    SELECT
        ss.ss_item_sk,
        ss.ss_hdemo_sk,
        ss.ss_sold_time_sk,
        SUM(ss.ss_net_paid)        AS total_net_paid,
        SUM(ss.ss_ext_sales_price) AS total_sales_price,
        COUNT(*)                     AS sales_cnt
    FROM store_sales ss
    GROUP BY ss.ss_item_sk, ss.ss_hdemo_sk, ss.ss_sold_time_sk
),
-- Aggregate store returns per item, household, return time and ticket number
returns_agg AS (
    SELECT
        sr.sr_item_sk,
        sr.sr_hdemo_sk,
        sr.sr_return_time_sk,
        sr.sr_ticket_number,
        SUM(sr.sr_return_amt)    AS total_return_amt,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        COUNT(*)                  AS returns_cnt
    FROM store_returns sr
    GROUP BY sr.sr_item_sk, sr.sr_hdemo_sk, sr.sr_return_time_sk, sr.sr_ticket_number
),
-- Distinct item identifiers that appear in sales
sales_items AS (
    SELECT DISTINCT i_sales.i_item_id
    FROM sales_agg sa
    JOIN item i_sales ON sa.ss_item_sk = i_sales.i_item_sk
),
-- Distinct item identifiers that appear in returns
returns_items AS (
    SELECT DISTINCT i_return.i_item_id
    FROM returns_agg ra
    JOIN item i_return ON ra.sr_item_sk = i_return.i_item_sk
),
-- Items that have both sales and returns (INTERSECT of the two sets)
common_items AS (
    SELECT i_item_id FROM sales_items
    INTERSECT
    SELECT i_item_id FROM returns_items
),
-- Detailed sales rows for the common items, joining several dimension tables
sales_detail AS (
    SELECT
        i_sales.i_item_id,
        i_sales.i_brand,
        i_sales.i_category,
        hd_sales.hd_buy_potential,
        t_sales.t_hour               AS sale_hour,
        sa.total_net_paid,
        sa.total_sales_price,
        sa.sales_cnt,
        CASE WHEN sa.total_net_paid > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM sales_agg sa
    JOIN item i_sales ON sa.ss_item_sk = i_sales.i_item_sk
    JOIN household_demographics hd_sales ON sa.ss_hdemo_sk = hd_sales.hd_demo_sk
    JOIN time_dim t_sales ON sa.ss_sold_time_sk = t_sales.t_time_sk
    WHERE i_sales.i_item_id IN (SELECT i_item_id FROM common_items)
),
-- Detailed return rows for the common items, joining several dimension tables and store_sales twice (ticket & item joins)
returns_detail AS (
    SELECT
        i_return.i_item_id,
        i_return.i_brand,
        i_return.i_category,
        hd_return.hd_buy_potential,
        t_return.t_hour               AS return_hour,
        ra.total_return_amt,
        ra.total_refunded_cash,
        ra.returns_cnt,
        CASE WHEN ra.total_return_amt > 0 THEN 'Returned' ELSE 'NoReturn' END AS return_flag
    FROM returns_agg ra
    JOIN item i_return ON ra.sr_item_sk = i_return.i_item_sk
    JOIN household_demographics hd_return ON ra.sr_hdemo_sk = hd_return.hd_demo_sk
    JOIN time_dim t_return ON ra.sr_return_time_sk = t_return.t_time_sk
    -- Join to store_sales on ticket number (rule 1)
    JOIN store_sales ss_on_ticket ON ra.sr_ticket_number = ss_on_ticket.ss_ticket_number
    -- Join to store_sales on item key (rule 2)
    JOIN store_sales ss_on_item   ON ra.sr_item_sk = ss_on_item.ss_item_sk
    WHERE i_return.i_item_id IN (SELECT i_item_id FROM common_items)
),
-- Union sales and returns into a single stream
combined AS (
    SELECT
        i_item_id   AS item_id,
        i_brand,
        i_category,
        hd_buy_potential,
        sale_hour   AS hour,
        total_net_paid      AS metric_value,
        sales_cnt           AS metric_count,
        profit_flag         AS metric_flag,
        'sales'   AS source
    FROM sales_detail
    UNION ALL
    SELECT
        i_item_id   AS item_id,
        i_brand,
        i_category,
        hd_buy_potential,
        return_hour AS hour,
        total_return_amt    AS metric_value,
        returns_cnt         AS metric_count,
        return_flag         AS metric_flag,
        'returns' AS source
    FROM returns_detail
)
SELECT
    item_id,
    i_brand,
    i_category,
    hd_buy_potential,
    hour,
    SUM(metric_value) AS total_metric,
    SUM(metric_count) AS total_count,
    CASE
        WHEN SUM(CASE WHEN metric_flag = 'Profit' THEN metric_value ELSE 0 END) > 0
            THEN 'Overall Profit'
        ELSE 'Overall Loss'
    END AS overall_status,
    COUNT(DISTINCT source) AS sources_included
FROM combined
GROUP BY item_id, i_brand, i_category, hd_buy_potential, hour
ORDER BY total_metric DESC
LIMIT 100
