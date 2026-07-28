WITH max_dmail_cost AS (
    SELECT max(p_cost) AS val
    FROM promotion
    WHERE p_channel_dmail = 'Y'
)
SELECT activity_date_sk,
       wp_web_page_id,
       gender_category,
       amount,
       max_dmail_promo_cost,
       activity_type
FROM (
    SELECT
        ws.ws_sold_date_sk AS activity_date_sk,
        wp.wp_web_page_id,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_category,
        ws.ws_net_paid AS amount,
        max_dc.val AS max_dmail_promo_cost,
        'sale' AS activity_type
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    CROSS JOIN max_dmail_cost max_dc
    WHERE p.p_channel_dmail = 'Y'
      AND wp.wp_access_date_sk = 2452620
) AS sales_data
UNION ALL
SELECT activity_date_sk,
       wp_web_page_id,
       gender_category,
       amount,
       max_dmail_promo_cost,
       activity_type
FROM (
    SELECT
        wr.wr_returned_date_sk AS activity_date_sk,
        wp.wp_web_page_id,
        CASE 
            WHEN cd.cd_gender = 'M' THEN 'Male'
            WHEN cd.cd_gender = 'F' THEN 'Female'
            ELSE 'Other'
        END AS gender_category,
        wr.wr_return_amt AS amount,
        max_dc.val AS max_dmail_promo_cost,
        'return' AS activity_type
    FROM web_returns wr
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    CROSS JOIN max_dmail_cost max_dc
    WHERE wr.wr_fee > 30
      AND cd.cd_credit_rating = 'A'
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_order_number = wr.wr_order_number
            AND ws2.ws_quantity > 0
      )
) AS returns_data
ORDER BY activity_date_sk DESC, amount DESC
LIMIT 100
