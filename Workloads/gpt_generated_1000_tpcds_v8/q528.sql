WITH unioned AS (
    SELECT
        p.p_promo_sk AS promo_sk,
        p.p_channel_dmail AS channel_dmail,
        p.p_channel_details AS channel_details,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        (SELECT AVG(ws3.ws_ext_sales_price)
         FROM web_sales ws3
         WHERE ws3.ws_promo_sk = p.p_promo_sk) AS avg_sales_price
    FROM promotion p
    JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    WHERE regexp_like(p.p_channel_details, '(?i)family|young')
      AND p.p_channel_details LIKE '%family%'
      AND p.p_channel_dmail = 'Y'
      AND ws.ws_ext_tax > 20
      AND NOT EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_promo_sk = p.p_promo_sk
            AND ws2.ws_ext_ship_cost > 2000
      )
    GROUP BY p.p_promo_sk, p.p_channel_dmail, p.p_channel_details, p.p_discount_active

    UNION DISTINCT

    SELECT
        NULL AS promo_sk,
        p.p_channel_dmail AS channel_dmail,
        NULL AS channel_details,
        CASE WHEN p.p_discount_active = 'Y' THEN 'Active' ELSE 'Inactive' END AS promo_status,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        COUNT(*) AS order_cnt,
        NULL AS avg_sales_price
    FROM promotion p
    JOIN web_sales ws ON ws.ws_promo_sk = p.p_promo_sk
    WHERE p.p_channel_dmail = 'N'
      AND REGEXP_LIKE(p.p_promo_id, '^PROMO[0-9]{3}$')
    GROUP BY p.p_channel_dmail, p.p_discount_active
)
SELECT
    promo_sk,
    channel_dmail,
    channel_details,
    promo_status,
    SUM(total_sales) AS total_sales,
    SUM(total_profit) AS total_profit,
    SUM(order_cnt) AS order_cnt,
    AVG(avg_sales_price) AS avg_sales_price,
    CONCAT(COALESCE(channel_dmail, ''), '-', promo_status) AS channel_status_key,
    SUBSTRING(COALESCE(channel_details, ''), 1, 30) AS short_details,
    ROW_NUMBER() OVER (PARTITION BY promo_sk ORDER BY SUM(total_sales) DESC) AS sales_rank,
    GROUPING(promo_sk) AS grp_promo,
    GROUPING(channel_dmail) AS grp_channel,
    GROUPING(promo_status) AS grp_status
FROM unioned
GROUP BY CUBE(promo_sk, channel_dmail, promo_status, channel_details)
HAVING (promo_sk IS NOT NULL OR channel_dmail IS NOT NULL)
ORDER BY total_sales DESC
LIMIT 100
