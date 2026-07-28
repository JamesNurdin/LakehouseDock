WITH sr_agg AS (
    SELECT
        sr_cdemo_sk,
        sr_addr_sk,
        SUM(sr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt
    FROM store_returns
    WHERE sr_return_quantity > 1
      AND sr_fee > 0
    GROUP BY sr_cdemo_sk, sr_addr_sk
)
SELECT
    p.p_promo_id,
    w.w_warehouse_name,
    ca.ca_city,
    cd.cd_education_status,
    SUM(ws.ws_net_profit) AS total_profit,
    SUM(sr_agg.total_net_loss) AS total_loss,
    SUM(ws.ws_net_profit) - SUM(sr_agg.total_net_loss) AS net_gain,
    COUNT(DISTINCT ws.ws_order_number) AS orders_cnt
FROM sr_agg
JOIN customer_demographics cd
    ON sr_agg.sr_cdemo_sk = cd.cd_demo_sk
JOIN customer_address ca
    ON sr_agg.sr_addr_sk = ca.ca_address_sk
JOIN web_sales ws
    ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
   AND ws.ws_bill_addr_sk = ca.ca_address_sk
JOIN promotion p
    ON ws.ws_promo_sk = p.p_promo_sk
JOIN warehouse w
    ON ws.ws_warehouse_sk = w.w_warehouse_sk
WHERE ca.ca_state = 'CA'
  AND ca.ca_country = 'United States'
  AND cd.cd_education_status = 'College'
  AND cd.cd_purchase_estimate >= 8000
  AND p.p_discount_active = 'Y'
  AND w.w_county = 'Bronx County'
GROUP BY p.p_promo_id, w.w_warehouse_name, ca.ca_city, cd.cd_education_status
HAVING SUM(ws.ws_net_profit) > 10000
ORDER BY net_gain DESC
LIMIT 20
