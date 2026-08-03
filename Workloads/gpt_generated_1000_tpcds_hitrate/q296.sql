WITH recent_dates AS (
    SELECT d_date_sk, d_date
    FROM date_dim
    WHERE d_year = 2020
)
,
sales_without_return AS (
    SELECT
        cs.cs_order_number        AS order_id,
        cs.cs_sold_date_sk        AS date_sk,
        dd.d_date                 AS trans_date,
        cs.cs_net_paid            AS amount,
        p.p_promo_name            AS description
    FROM catalog_sales cs
    JOIN recent_dates rd ON cs.cs_sold_date_sk = rd.d_date_sk
    JOIN date_dim dd ON cs.cs_sold_date_sk = dd.d_date_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE p.p_channel_tv = 'Y'
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_returns cr
          WHERE cr.cr_order_number = cs.cs_order_number
      )
)
,
returns_with_high_loss AS (
    SELECT
        cr.cr_order_number        AS order_id,
        cr.cr_returned_date_sk    AS date_sk,
        dd.d_date                 AS trans_date,
        cr.cr_net_loss            AS amount,
        r.r_reason_desc           AS description
    FROM catalog_returns cr
    JOIN recent_dates rd ON cr.cr_returned_date_sk = rd.d_date_sk
    JOIN date_dim dd ON cr.cr_returned_date_sk = dd.d_date_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE cr.cr_net_loss > (
        SELECT AVG(cr2.cr_net_loss)
        FROM catalog_returns cr2
        JOIN recent_dates rd2 ON cr2.cr_returned_date_sk = rd2.d_date_sk
    )
      AND NOT EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_order_number = cr.cr_order_number
      )
)
SELECT order_id,
       date_sk,
       trans_date,
       amount,
       description
FROM sales_without_return
UNION ALL
SELECT order_id,
       date_sk,
       trans_date,
       amount,
       description
FROM returns_with_high_loss
ORDER BY trans_date DESC
LIMIT 100
