/* goal: Compare high‑value store and web sales for the year 2001, showing only customers who also had a store return in that year. */
WITH store_tx AS (
    SELECT DISTINCT
        c.c_customer_id,
        d.d_date AS sales_date,
        ss.ss_net_paid AS sales_amount,
        'store' AS channel,
        CASE WHEN ss.ss_net_paid > 1000 THEN 'high' ELSE 'normal' END AS amount_category
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND EXISTS (
          SELECT 1
          FROM store_returns sr
          JOIN date_dim dr
              ON sr.sr_returned_date_sk = dr.d_date_sk
          WHERE sr.sr_customer_sk = c.c_customer_sk
            AND dr.d_year = 2001
      )
),
web_tx AS (
    SELECT DISTINCT
        c.c_customer_id,
        d.d_date AS sales_date,
        ws.ws_net_paid AS sales_amount,
        'web' AS channel,
        CASE WHEN ws.ws_net_paid > 1000 THEN 'high' ELSE 'normal' END AS amount_category
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    LEFT JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_discount_active = 'Y'
)
SELECT *
FROM (
    SELECT * FROM store_tx
    UNION ALL
    SELECT * FROM web_tx
) AS combined
ORDER BY sales_amount DESC
LIMIT 100
