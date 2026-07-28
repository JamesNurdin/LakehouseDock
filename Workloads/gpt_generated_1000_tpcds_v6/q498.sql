WITH promo_order_counts AS (
    SELECT p.p_promo_sk,
           COUNT(DISTINCT ws2.ws_order_number) AS web_order_cnt
    FROM promotion p
    JOIN web_sales ws2 ON ws2.ws_promo_sk = p.p_promo_sk
    GROUP BY p.p_promo_sk
)
SELECT
    d.d_date,
    p.p_promo_name,
    cd.cd_gender,
    ss.ss_net_paid AS store_net_paid,
    cs.cs_net_paid AS catalog_net_paid,
    ws.ws_net_paid AS web_net_paid,
    wr.wr_net_loss,
    (COALESCE(ss.ss_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ws.ws_net_paid, 0) - COALESCE(wr.wr_net_loss, 0)) AS total_net,
    pod.web_order_cnt,
    ROW_NUMBER() OVER (PARTITION BY p.p_promo_id ORDER BY (COALESCE(ss.ss_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ws.ws_net_paid, 0) - COALESCE(wr.wr_net_loss, 0)) DESC) AS promo_rank
FROM date_dim d
JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
JOIN customer_demographics cd ON cd.cd_demo_sk = ss.ss_cdemo_sk
JOIN promotion p ON p.p_promo_sk = ss.ss_promo_sk
JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    AND cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN catalog_page cp ON cp.cp_catalog_page_sk = cs.cs_catalog_page_sk
JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    AND ws.ws_bill_cdemo_sk = cd.cd_demo_sk
JOIN web_site wsit ON wsit.web_site_sk = ws.ws_web_site_sk
JOIN web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
    AND wr.wr_item_sk = ws.ws_item_sk
    AND wr.wr_order_number = ws.ws_order_number
JOIN promo_order_counts pod ON pod.p_promo_sk = p.p_promo_sk
WHERE d.d_year = 2001
  AND p.p_channel_event = 'N'
  AND cd.cd_gender = 'F'
  AND wsit.web_country = 'United States'
ORDER BY total_net DESC
LIMIT 100
