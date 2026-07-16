WITH store_sales_agg AS (
    SELECT
        ss_store_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        AVG(ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS sales_cnt
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY ss_store_sk
),
store_info AS (
    SELECT
        s_store_sk,
        s_store_name,
        s_state,
        s_city,
        s_market_id
    FROM store
    WHERE s_rec_end_date IS NULL OR s_rec_end_date > CURRENT_DATE
),
store_sales_enriched AS (
    SELECT
        si.s_store_sk,
        si.s_store_name,
        si.s_state,
        si.s_city,
        si.s_market_id,
        sa.total_sales,
        sa.total_profit,
        sa.avg_discount,
        sa.sales_cnt,
        RANK() OVER (ORDER BY sa.total_profit DESC) AS profit_rank
    FROM store_sales_agg sa
    JOIN store_info si ON sa.ss_store_sk = si.s_store_sk
),
top_return_reason AS (
    SELECT
        r.r_reason_desc,
        SUM(cr.cr_return_amount) AS total_return_amount
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_returned_date_sk BETWEEN 2451545 AND 2451910
    GROUP BY r.r_reason_desc
    ORDER BY total_return_amount DESC
    LIMIT 1
)
SELECT
    sse.s_store_name,
    sse.s_city,
    sse.s_state,
    sse.total_sales,
    sse.total_profit,
    sse.avg_discount,
    sse.sales_cnt,
    sse.profit_rank,
    trr.r_reason_desc AS top_return_reason,
    trr.total_return_amount AS top_return_amount
FROM store_sales_enriched sse
CROSS JOIN top_return_reason trr
WHERE sse.profit_rank <= 10
ORDER BY sse.total_profit DESC
