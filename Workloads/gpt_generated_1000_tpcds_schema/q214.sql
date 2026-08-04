WITH cr_filtered AS (
    SELECT cr.cr_order_number
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE ca.ca_state = 'CA'
      AND cd.cd_credit_rating = 'Good'
      AND d.d_year = 2001
      AND cr.cr_order_number IN (
            SELECT ws.ws_order_number
            FROM web_sales ws
            JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
            WHERE p.p_channel_email = 'Y'
        )
),
ws_excluded AS (
    SELECT ws.ws_order_number
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE p.p_channel_email = 'N'
      AND d.d_year = 2001
)
SELECT cr_order_number
FROM cr_filtered
EXCEPT
SELECT ws_order_number
FROM ws_excluded
LIMIT 100
