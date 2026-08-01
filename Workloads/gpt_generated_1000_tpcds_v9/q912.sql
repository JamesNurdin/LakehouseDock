WITH sales AS (
    SELECT
        'sale' AS source_type,
        ss.ss_store_sk AS store_sk,
        ss.ss_item_sk AS item_sk,
        i.i_product_name AS product_name,
        SUM(ss.ss_quantity) AS total_quantity,
        SUM(ss.ss_ext_sales_price) AS total_amount,
        SUM(ss.ss_net_profit) AS net_profit,
        ROW_NUMBER() OVER (PARTITION BY ss.ss_store_sk ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank,
        CAST(NULL AS decimal(7,2)) AS total_refunded_cash_for_item
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM web_page wp WHERE wp.wp_customer_sk = c.c_customer_sk
    )
      AND i.i_color IN ('turquoise', 'rosy', 'snow')
    GROUP BY ss.ss_store_sk, ss.ss_item_sk, i.i_product_name
    HAVING SUM(ss.ss_ext_sales_price) > 1000
),
returns AS (
    SELECT
        'return' AS source_type,
        sr.sr_store_sk AS store_sk,
        sr.sr_item_sk AS item_sk,
        i.i_product_name AS product_name,
        SUM(sr.sr_return_quantity) AS total_quantity,
        SUM(sr.sr_return_amt_inc_tax) AS total_amount,
        -SUM(sr.sr_net_loss) AS net_profit,
        ROW_NUMBER() OVER (PARTITION BY sr.sr_store_sk ORDER BY SUM(sr.sr_return_amt_inc_tax) DESC) AS profit_rank,
        (SELECT COALESCE(SUM(sr2.sr_refunded_cash), 0)
         FROM store_returns sr2
         WHERE sr2.sr_item_sk = sr.sr_item_sk) AS total_refunded_cash_for_item
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE NOT EXISTS (
        SELECT 1 FROM web_page wp WHERE wp.wp_customer_sk = c.c_customer_sk
    )
      AND i.i_color = 'yellow'
    GROUP BY sr.sr_store_sk, sr.sr_item_sk, i.i_product_name
    HAVING SUM(sr.sr_return_quantity) > 0
)
SELECT source_type,
       store_sk,
       item_sk,
       product_name,
       total_quantity,
       total_amount,
       net_profit,
       profit_rank,
       total_refunded_cash_for_item
FROM sales
UNION ALL
SELECT source_type,
       store_sk,
       item_sk,
       product_name,
       total_quantity,
       total_amount,
       net_profit,
       profit_rank,
       total_refunded_cash_for_item
FROM returns
ORDER BY store_sk, profit_rank
LIMIT 100
