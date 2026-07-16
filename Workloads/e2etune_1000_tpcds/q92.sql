WITH store_agg AS (
    SELECT
        ss_store_sk,
        SUM(ss_net_paid_inc_tax) AS total_sales,
        SUM(ss_net_profit) AS total_profit,
        AVG(ss_ext_discount_amt) AS avg_discount,
        COUNT(*) AS transaction_cnt,
        SUM(ss_quantity) AS total_quantity
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2450100
    GROUP BY ss_store_sk
),
store_ranked AS (
    SELECT
        ss_store_sk,
        total_sales,
        total_profit,
        avg_discount,
        transaction_cnt,
        total_quantity,
        total_profit / NULLIF(total_sales, 0) AS profit_margin,
        ROW_NUMBER() OVER (ORDER BY total_profit DESC) AS profit_rank
    FROM store_agg
    WHERE total_sales > 10000
)
SELECT
    ws.web_site_id,
    ws.web_name,
    sr.ss_store_sk,
    sr.total_sales,
    sr.total_profit,
    sr.profit_margin,
    sr.profit_rank
FROM store_ranked sr
JOIN web_site ws
    ON sr.ss_store_sk = ws.web_site_sk
WHERE sr.profit_margin > 0.05
ORDER BY sr.profit_margin DESC
LIMIT 10
