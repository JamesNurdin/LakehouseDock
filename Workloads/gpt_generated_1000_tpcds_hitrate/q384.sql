WITH sales_agg AS (
   SELECT
       p.p_promo_id,
       ws.ws_web_site_sk,
       SUM(ws.ws_net_profit) AS total_profit,
       COUNT(*) AS sales_cnt,
       AVG(ws.ws_list_price) AS avg_list_price
   FROM web_sales ws
   JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
   JOIN web_site site ON ws.ws_web_site_sk = site.web_site_sk
   JOIN household_demographics hd ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
   JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
   LEFT JOIN web_returns wr ON wr.wr_order_number = ws.ws_order_number
   LEFT JOIN catalog_returns cr ON cr.cr_refunded_hdemo_sk = hd.hd_demo_sk
   WHERE ws.ws_list_price > 100
     AND wp.wp_image_count >= 2
     AND hd.hd_vehicle_count > 1
     AND site.web_country = 'United States'
     AND p.p_channel_email = 'Y'
     AND EXISTS (
         SELECT 1 FROM catalog_returns cr2
         WHERE cr2.cr_returned_date_sk = ws.ws_sold_date_sk
           AND cr2.cr_net_loss > 0
     )
   GROUP BY p.p_promo_id, ws.ws_web_site_sk
)
SELECT
    sa.p_promo_id,
    site.web_name,
    sa.total_profit,
    sa.sales_cnt,
    sa.avg_list_price,
    pc.avg_price_component
FROM sales_agg sa
JOIN web_site site ON sa.ws_web_site_sk = site.web_site_sk
JOIN promotion p ON sa.p_promo_id = p.p_promo_id
CROSS JOIN LATERAL (
    SELECT AVG(price_component) AS avg_price_component
    FROM UNNEST(ARRAY[sa.avg_list_price, sa.total_profit]) AS t(price_component)
) pc
WHERE sa.total_profit > 5000
ORDER BY sa.total_profit DESC
OFFSET 0 FETCH NEXT 100 ROWS ONLY
