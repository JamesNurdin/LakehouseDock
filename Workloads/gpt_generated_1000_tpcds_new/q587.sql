WITH cat_promo AS (
    SELECT
        cs.cs_order_number,
        cs.cs_ext_sales_price,
        cs.cs_net_profit,
        cs.cs_coupon_amt,
        cs.cs_ext_tax,
        cs.cs_promo_sk,
        p.p_promo_id,
        p.p_channel_press,
        p.p_channel_radio,
        p.p_discount_active
    FROM catalog_sales cs
    FULL OUTER JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    WHERE cs.cs_ext_sales_price > 500
      AND cs.cs_net_profit > 0
      AND (p.p_channel_press = 'N' OR p.p_channel_radio = 'N')
      AND p.p_discount_active = 'Y'
      AND cs.cs_ext_tax < 200
      AND cs.cs_coupon_amt >= 0
),
ws_filtered AS (
    SELECT
        ws.ws_order_number,
        ws.ws_ext_sales_price,
        ws.ws_net_profit,
        ws.ws_coupon_amt,
        ws.ws_ext_tax,
        ws.ws_promo_sk,
        ws.ws_ship_date_sk
    FROM web_sales ws
    WHERE ws.ws_ext_sales_price > 500
      AND ws.ws_net_profit > 0
      AND ws.ws_ext_tax < 200
      AND ws.ws_coupon_amt >= 0
      AND ws.ws_ship_date_sk BETWEEN 2451450 AND 2452800
      AND ws.ws_promo_sk IS NOT NULL
),
common_orders AS (
    SELECT cs_order_number AS order_number
    FROM cat_promo
    INTERSECT
    SELECT ws_order_number
    FROM ws_filtered
)
SELECT
    cp.cs_order_number,
    cp.p_promo_id,
    cp.cs_ext_sales_price,
    ws.ws_ext_sales_price,
    cp.cs_net_profit,
    ws.ws_net_profit,
    CASE WHEN cp.cs_ext_sales_price > ws.ws_ext_sales_price THEN 'CATALOG' ELSE 'WEB' END AS higher_source,
    RANK() OVER (PARTITION BY cp.p_promo_id ORDER BY (cp.cs_ext_sales_price + ws.ws_ext_sales_price) DESC) AS promo_sales_rank,
    SUM(cp.cs_ext_sales_price) OVER (PARTITION BY cp.p_promo_id ORDER BY cp.cs_order_number ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_sum_sales
FROM cat_promo cp
JOIN web_sales ws
    ON ws.ws_promo_sk = cp.cs_promo_sk
JOIN common_orders co
    ON co.order_number = cp.cs_order_number
WHERE cp.cs_ext_sales_price IS NOT NULL
  AND ws.ws_ext_sales_price IS NOT NULL
  AND cp.p_channel_press = 'N'
  AND cp.p_discount_active = 'Y'
  AND ws.ws_ship_date_sk >= 2451500
  AND ws.ws_ship_date_sk <= 2452600
ORDER BY promo_sales_rank ASC, cp.cs_order_number DESC
LIMIT 100
