WITH sales AS (
    SELECT ss.ss_ticket_number,
           ss.ss_store_sk,
           ss.ss_sold_date_sk,
           d.d_date,
           ss.ss_net_paid,
           CASE WHEN ss.ss_net_paid > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2001
      AND s.s_state = 'CA'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = ss.ss_promo_sk
            AND p.p_discount_active = 'Y'
      )
),
returns AS (
    SELECT sr.sr_ticket_number,
           sr.sr_store_sk,
           sr.sr_returned_date_sk,
           d.d_date,
           sr.sr_net_loss,
           CASE WHEN sr.sr_net_loss > 0 THEN 'Loss' ELSE 'NoLoss' END AS loss_flag
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
)
SELECT ticket_number,
       store_sk,
       trans_date,
       amount,
       flag
FROM (
    SELECT ss_ticket_number AS ticket_number,
           ss_store_sk AS store_sk,
           d_date AS trans_date,
           ss_net_paid AS amount,
           profit_flag AS flag
    FROM sales
    UNION ALL
    SELECT sr_ticket_number AS ticket_number,
           sr_store_sk AS store_sk,
           d_date AS trans_date,
           -sr_net_loss AS amount,
           loss_flag AS flag
    FROM returns
) combined
EXCEPT
SELECT ticket_number,
       store_sk,
       trans_date,
       amount,
       flag
FROM (
    SELECT s.ss_ticket_number AS ticket_number,
           s.ss_store_sk AS store_sk,
           s.d_date AS trans_date,
           s.ss_net_paid AS amount,
           s.profit_flag AS flag
    FROM sales s
    JOIN store_returns sr ON s.ss_ticket_number = sr.sr_ticket_number
) overlapped
ORDER BY amount DESC
LIMIT 100
