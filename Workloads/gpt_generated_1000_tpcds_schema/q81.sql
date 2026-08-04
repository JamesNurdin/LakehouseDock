WITH promo_exp AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_start_date_sk,
        p.p_end_date_sk,
        p.p_item_sk,
        p.p_cost,
        p.p_response_target,
        p.p_promo_name,
        p.p_channel_dmail,
        p.p_channel_email,
        p.p_channel_catalog,
        p.p_channel_tv,
        p.p_channel_radio,
        p.p_channel_press,
        p.p_channel_event,
        p.p_channel_demo,
        p.p_channel_details,
        p.p_purpose,
        p.p_discount_active,
        split(p.p_channel_details, ',') AS channel_arr
    FROM promotion p
),
promo_unnested AS (
    SELECT
        pe.*, 
        TRIM(channel) AS channel
    FROM promo_exp pe
    CROSS JOIN UNNEST(pe.channel_arr) AS t(channel)
)
SELECT
    ws.ws_web_site_sk,
    wsite.web_site_id,
    ws.ws_sold_date_sk,
    ws.ws_order_number,
    COUNT(DISTINCT cs.cs_order_number) AS catalog_order_cnt,
    SUM(cs.cs_net_paid) AS total_catalog_net_paid,
    SUM(ws.ws_net_paid) AS total_web_net_paid,
    AVG(cs.cs_ext_discount_amt) AS avg_catalog_discount,
    MIN(ws.ws_ext_sales_price) AS min_web_sales_price,
    MAX(ws.ws_ext_sales_price) AS max_web_sales_price,
    COUNT(DISTINCT pu.channel) AS distinct_channel_cnt
FROM catalog_sales cs
RIGHT OUTER JOIN promo_unnested pu
    ON cs.cs_promo_sk = pu.p_promo_sk
JOIN web_sales ws
    ON ws.ws_promo_sk = pu.p_promo_sk
JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
WHERE
    pu.p_discount_active = 'N'
    AND pu.p_channel_catalog = 'N'
    AND wsite.web_zip = '54536'
    AND wsite.web_manager = 'James Austin'
    AND cs.cs_ext_list_price > 5000
    AND ws.ws_ext_list_price < 10000
GROUP BY
    ws.ws_web_site_sk,
    wsite.web_site_id,
    ws.ws_sold_date_sk,
    ws.ws_order_number
ORDER BY total_web_net_paid DESC
LIMIT 100
