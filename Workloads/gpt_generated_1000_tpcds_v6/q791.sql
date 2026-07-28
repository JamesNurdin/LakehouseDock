WITH store_part AS (
    SELECT
        d.d_date AS sale_date,
        CASE WHEN p.p_channel_email = 'Y' THEN 'Email' ELSE 'Other' END AS channel_type,
        ss.ss_net_paid AS sales_amount,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY ss.ss_net_paid DESC) AS sales_rank
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.store s ON ss.ss_store_sk = s.s_store_sk
    JOIN tpcds.promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2001
      AND p.p_channel_email = 'Y'
),
web_part AS (
    SELECT
        d.d_date AS sale_date,
        CASE WHEN p.p_channel_radio = 'Y' THEN 'Radio' ELSE 'Other' END AS channel_type,
        ws.ws_net_paid AS sales_amount,
        ROW_NUMBER() OVER (PARTITION BY ws.ws_order_number ORDER BY ws.ws_net_paid DESC) AS sales_rank
    FROM tpcds.web_sales ws
    JOIN tpcds.date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE d.d_year = 2002
      AND p.p_channel_radio = 'Y'
)
SELECT *
FROM store_part
UNION ALL
SELECT *
FROM web_part
ORDER BY sales_amount DESC
LIMIT 100
