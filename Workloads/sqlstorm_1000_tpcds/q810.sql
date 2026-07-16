WITH sales_agg AS (
    SELECT
        ss.ss_store_sk,
        s.s_store_name,
        ss.ss_item_sk,
        i.i_item_id,
        i.i_product_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_net_paid) AS total_net_paid,
        SUM(ss.ss_net_profit) AS total_net_profit,
        MAX(ss.ss_sold_date_sk) AS last_sale_date_sk
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY ss.ss_store_sk, s.s_store_name, ss.ss_item_sk, i.i_item_id, i.i_product_name
),
returns_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_item_sk,
        SUM(sr.sr_return_quantity) AS total_return_qty,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        MAX(sr.sr_returned_date_sk) AS last_return_date_sk
    FROM store_returns sr
    GROUP BY sr.sr_store_sk, sr.sr_item_sk
),
combined AS (
    SELECT
        sa.ss_store_sk,
        sa.s_store_name,
        sa.ss_item_sk,
        sa.i_item_id,
        sa.i_product_name,
        sa.total_quantity,
        sa.total_net_paid,
        sa.total_net_profit,
        COALESCE(ra.total_return_qty, 0) AS total_return_qty,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        (sa.total_net_profit - COALESCE(ra.total_return_amount, 0)) AS net_profit_after_returns,
        CASE
            WHEN (sa.total_net_profit - COALESCE(ra.total_return_amount, 0)) > 10000 THEN 'HIGH'
            WHEN (sa.total_net_profit - COALESCE(ra.total_return_amount, 0)) BETWEEN 0 AND 10000 THEN 'MEDIUM'
            ELSE 'LOW'
        END AS profit_category,
        CONCAT('Store: ', sa.s_store_name, ' Item: ', sa.i_item_id) AS store_item_label,
        ROW_NUMBER() OVER (PARTITION BY sa.ss_store_sk ORDER BY (sa.total_net_profit - COALESCE(ra.total_return_amount, 0)) DESC) AS profit_rank,
        (SELECT MAX(sr2.sr_returned_date_sk)
         FROM store_returns sr2
         WHERE sr2.sr_store_sk = sa.ss_store_sk
           AND sr2.sr_item_sk = sa.ss_item_sk) AS latest_return_date_sk,
        sa.last_sale_date_sk
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.ss_store_sk = ra.sr_store_sk
       AND sa.ss_item_sk = ra.sr_item_sk
),
filtered AS (
    SELECT *
    FROM combined c
    WHERE c.total_quantity > (
            SELECT AVG(ss2.ss_quantity)
            FROM store_sales ss2
            WHERE ss2.ss_store_sk = c.ss_store_sk
        )
      AND c.latest_return_date_sk IS NOT NULL
      AND c.profit_rank <= 5
)
SELECT
    f.ss_store_sk,
    f.s_store_name,
    f.i_item_id,
    f.i_product_name,
    f.total_quantity,
    f.total_net_paid,
    f.net_profit_after_returns,
    f.profit_category,
    f.store_item_label,
    f.profit_rank,
    d_last.d_date AS last_sale_date,
    d_ret.d_date AS latest_return_date,
    SUM(f.net_profit_after_returns) OVER (PARTITION BY f.ss_store_sk ORDER BY f.profit_rank ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM filtered f
LEFT JOIN date_dim d_last ON f.last_sale_date_sk = d_last.d_date_sk
LEFT JOIN date_dim d_ret ON f.latest_return_date_sk = d_ret.d_date_sk
UNION ALL
SELECT
    NULL,
    'ALL STORES',
    NULL,
    NULL,
    SUM(f.total_quantity),
    SUM(f.total_net_paid),
    SUM(f.net_profit_after_returns),
    NULL,
    'SUMMARY',
    NULL,
    NULL,
    NULL,
    SUM(f.net_profit_after_returns)
FROM filtered f
ORDER BY ss_store_sk, profit_rank
