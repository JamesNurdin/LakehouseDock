WITH sales_part AS (
    SELECT
        c.c_customer_id AS customer_id,
        ss.ss_sold_date_sk AS date_key,
        ss.ss_net_paid AS amount,
        CASE WHEN ss.ss_quantity > 5 THEN 'Large' ELSE 'Small' END AS qty_category,
        CASE WHEN ss.ss_net_paid > (
                SELECT AVG(ss2.ss_net_paid)
                FROM store_sales ss2
                WHERE ss2.ss_store_sk = ss.ss_store_sk
            ) THEN 'AboveAvg' ELSE 'BelowAvg' END AS profit_flag
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN time_dim t ON ss.ss_sold_time_sk = t.t_time_sk
    WHERE s.s_state = 'CA'
      AND ss.ss_list_price > 20
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          WHERE sr.sr_customer_sk = ss.ss_customer_sk
            AND sr.sr_net_loss > 0
      )
),
returns_part AS (
    SELECT
        c.c_customer_id AS customer_id,
        sr.sr_returned_date_sk AS date_key,
        sr.sr_refunded_cash AS amount,
        CASE WHEN sr.sr_return_quantity > 3 THEN 'Large' ELSE 'Small' END AS qty_category,
        CASE WHEN sr.sr_refunded_cash > (
                SELECT AVG(sr2.sr_refunded_cash)
                FROM store_returns sr2
                WHERE sr2.sr_store_sk = sr.sr_store_sk
            ) THEN 'AboveAvg' ELSE 'BelowAvg' END AS profit_flag
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN time_dim t ON sr.sr_return_time_sk = t.t_time_sk
    WHERE s.s_state = 'CA'
      AND sr.sr_refunded_cash > 10
      AND EXISTS (
          SELECT 1
          FROM store_sales ss
          WHERE ss.ss_customer_sk = sr.sr_customer_sk
            AND ss.ss_net_paid > 0
      )
)
SELECT *
FROM (
    SELECT * FROM sales_part
    UNION ALL
    SELECT * FROM returns_part
) combined
ORDER BY amount DESC
LIMIT 100
