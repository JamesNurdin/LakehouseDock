WITH sales_joined AS (
  SELECT
    ws.ws_promo_sk,
    ws.ws_web_site_sk,
    ws.ws_order_number,
    ws.ws_net_profit,
    cd.cd_gender,
    hd.hd_dep_count,
    hd.hd_vehicle_count,
    p.p_channel_demo,
    ws.ws_sold_date_sk,
    wr.wr_order_number -- NULL when no return
  FROM web_sales ws
  JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
  JOIN web_site wsite
    ON ws.ws_web_site_sk = wsite.web_site_sk
  JOIN customer_demographics cd
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
  JOIN household_demographics hd
    ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
  LEFT JOIN web_returns wr
    ON ws.ws_order_number = wr.wr_order_number
   AND ws.ws_item_sk = wr.wr_item_sk
  WHERE hd.hd_dep_count >= 5
    AND hd.hd_vehicle_count > 0
    AND wsite.web_company_name = 'able'
    AND p.p_channel_demo = 'N'
    AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450100
),
promo_site_agg AS (
  SELECT
    ws_promo_sk,
    ws_web_site_sk,
    SUM(ws_net_profit) AS total_net_profit,
    COUNT(DISTINCT ws_order_number) AS order_cnt,
    SUM(CASE WHEN wr_order_number IS NOT NULL THEN 1 ELSE 0 END) AS return_cnt
  FROM sales_joined
  GROUP BY ws_promo_sk, ws_web_site_sk
)
SELECT
  p.p_promo_id,
  wsite.web_name,
  psa.total_net_profit,
  psa.order_cnt,
  psa.return_cnt,
  (psa.return_cnt * 1.0 / NULLIF(psa.order_cnt, 0)) AS return_rate
FROM promo_site_agg psa
JOIN promotion p
  ON p.p_promo_sk = psa.ws_promo_sk
JOIN web_site wsite
  ON wsite.web_site_sk = psa.ws_web_site_sk
WHERE psa.total_net_profit > 1000
  AND (psa.return_cnt * 1.0 / NULLIF(psa.order_cnt, 0)) > 0.05
  AND EXISTS (
        SELECT 1
        FROM web_returns wr2
        JOIN web_sales ws2
          ON ws2.ws_order_number = wr2.wr_order_number
         AND ws2.ws_item_sk = wr2.wr_item_sk
        WHERE ws2.ws_promo_sk = psa.ws_promo_sk
          AND ws2.ws_web_site_sk = psa.ws_web_site_sk
          AND wr2.wr_return_amt > 100
      )
ORDER BY psa.total_net_profit DESC
LIMIT 100
