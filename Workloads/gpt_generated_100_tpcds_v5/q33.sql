WITH sales_data AS (
    SELECT d.d_year,
           SUM(ss.ss_net_paid) AS amount,
           'sales' AS source
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND cd.cd_gender = 'M'
    GROUP BY d.d_year
),
returns_data AS (
    SELECT d.d_year,
           SUM(sr.sr_refunded_cash) AS amount,
           'returns' AS source
    FROM store_returns sr
    JOIN store_sales ss ON sr.sr_ticket_number = ss.ss_ticket_number
                       AND sr.sr_item_sk = ss.ss_item_sk
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'N'
      AND cd.cd_gender = 'F'
    GROUP BY d.d_year
)
SELECT sd.d_year,
       sd.amount,
       sd.source
FROM sales_data sd
UNION ALL
SELECT rd.d_year,
       rd.amount,
       rd.source
FROM returns_data rd
ORDER BY d_year DESC, amount DESC
LIMIT 100
