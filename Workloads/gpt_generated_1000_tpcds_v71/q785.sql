WITH avg_store_sales AS (
    SELECT AVG(ss_ext_sales_price) AS avg_sales
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2021
)
SELECT *
FROM (
    SELECT DISTINCT
        c.c_customer_id,
        'Store' AS source,
        ss.ss_ticket_number        AS ticket_number,
        ss.ss_ext_sales_price      AS amount,
        d.d_date                   AS event_date
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2021
      AND ss.ss_ext_discount_amt > 10
      AND ss.ss_ext_sales_price > (SELECT avg_sales FROM avg_store_sales)
      AND EXISTS (
          SELECT 1
          FROM promotion p2
          WHERE p2.p_promo_sk = ss.ss_promo_sk
            AND p2.p_channel_email = 'Y'
      )
    UNION ALL
    SELECT DISTINCT
        c.c_customer_id,
        'CatalogReturn' AS source,
        cr.cr_order_number          AS ticket_number,
        -cr.cr_return_amount        AS amount,
        d2.d_date                   AS event_date
    FROM catalog_returns cr
    JOIN date_dim d2 ON cr.cr_returned_date_sk = d2.d_date_sk
    JOIN customer c ON cr.cr_returning_customer_sk = c.c_customer_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d2.d_year = 2021
      AND cr.cr_net_loss > 100
      AND cr.cr_return_amount > (SELECT avg_sales FROM avg_store_sales)
) AS combined
ORDER BY amount DESC
LIMIT 100
