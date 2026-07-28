WITH catalog_metrics AS (
    SELECT
        d.d_date AS sale_date,
        'Catalog' AS channel,
        SUM(cs.cs_net_paid) AS total_net_paid,
        SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
        SUM(cs.cs_net_paid) - SUM(COALESCE(cr.cr_return_amount, 0)) AS net_after_returns
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_order_number = cr.cr_order_number
        AND cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND EXISTS (
          SELECT 1
          FROM promotion p
          WHERE p.p_promo_sk = cs.cs_promo_sk
            AND p.p_start_date_sk > 2450300
      )
    GROUP BY d.d_date
),
web_metrics AS (
    SELECT
        d.d_date AS sale_date,
        'Web' AS channel,
        SUM(ws.ws_net_paid) AS total_net_paid,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_return_amount,
        SUM(ws.ws_net_paid) - SUM(COALESCE(wr.wr_return_amt, 0)) AS net_after_returns
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr
        ON ws.ws_order_number = wr.wr_order_number
        AND wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
      AND ws.ws_promo_sk IN (
          SELECT p_promo_sk
          FROM promotion
          WHERE p_channel_email = 'N'
      )
    GROUP BY d.d_date
)
SELECT sale_date,
       channel,
       total_net_paid,
       total_return_amount,
       net_after_returns
FROM (
    SELECT * FROM catalog_metrics
    UNION ALL
    SELECT * FROM web_metrics
) combined
ORDER BY sale_date, channel
LIMIT 100
