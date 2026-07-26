WITH item_sales AS (
    SELECT
        ss.ss_store_sk,
        ss.ss_item_sk,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_ext_discount_amt) AS total_discount_amount,
        SUM(ss.ss_net_profit) AS total_net_profit,
        COUNT(*) AS sales_transactions
    FROM store_sales ss
    GROUP BY ss.ss_store_sk, ss.ss_item_sk
),
item_returns AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_quantity_returned,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_transactions
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_item_sk
)
SELECT
    s.s_store_id,
    s.s_store_name,
    i.ss_item_sk AS item_sk,
    i.total_quantity_sold,
    i.total_sales_amount,
    i.total_discount_amount,
    CASE WHEN i.total_sales_amount = 0 THEN 0 ELSE i.total_discount_amount / i.total_sales_amount END AS discount_rate,
    i.total_net_profit,
    COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
    CASE WHEN i.total_quantity_sold = 0 THEN 0 ELSE COALESCE(r.total_quantity_returned, 0) * 1.0 / i.total_quantity_sold END AS return_rate,
    CASE 
        WHEN COALESCE(r.total_quantity_returned, 0) > i.total_quantity_sold * 0.5 THEN 'High Return'
        ELSE 'Normal Return'
    END AS return_flag,
    RANK() OVER (PARTITION BY s.s_store_id ORDER BY i.total_net_profit DESC) AS profit_rank_per_store
FROM store s
JOIN item_sales i ON s.s_store_sk = i.ss_store_sk
LEFT JOIN item_returns r ON s.s_store_sk = r.sr_store_sk AND i.ss_item_sk = r.sr_item_sk
WHERE s.s_store_id IS NOT NULL
ORDER BY s.s_store_id, profit_rank_per_store
