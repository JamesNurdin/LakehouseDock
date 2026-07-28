/*
  Goal: Combine daily aggregated catalog sales (weekday sales from promotions that used TV channel) with daily aggregated web returns (weekend returns from landing pages). The query shows the date, amount, transaction count and source type, ordered by date descending.
*/
WITH cs_agg AS (
    SELECT
        d.d_date AS event_date,
        SUM(cs.cs_ext_sales_price) AS amount,
        COUNT(DISTINCT cs.cs_order_number) AS txn_cnt,
        'Catalog' AS source
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_day_name IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday')
      AND p.p_channel_tv = 'Y'
    GROUP BY d.d_date
),
wr_agg AS (
    SELECT
        d.d_date AS event_date,
        SUM(wr.wr_return_amt) AS amount,
        COUNT(DISTINCT wr.wr_order_number) AS txn_cnt,
        'WebReturn' AS source
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_day_name IN ('Saturday', 'Sunday')
      AND wp.wp_type = 'Landing'
      AND EXISTS (
          SELECT 1
          FROM customer c
          JOIN catalog_sales cs2
              ON c.c_customer_sk = cs2.cs_bill_customer_sk
          WHERE cs2.cs_order_number = wr.wr_order_number
      )
    GROUP BY d.d_date
)
SELECT
    event_date,
    amount,
    txn_cnt,
    source
FROM cs_agg
UNION ALL
SELECT
    event_date,
    amount,
    txn_cnt,
    source
FROM wr_agg
ORDER BY event_date DESC
LIMIT 100
