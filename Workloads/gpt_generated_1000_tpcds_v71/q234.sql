WITH sales_summary AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        SUM(cs.cs_net_paid) AS cat_net_paid,
        SUM(ws.ws_net_paid) AS web_net_paid,
        COUNT(DISTINCT cs.cs_order_number) AS cat_orders,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN web_sales ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE cs.cs_net_paid > 500
      AND ws.ws_net_paid > 500
      AND i.i_color IN ('tan', 'smoke')
      AND p.p_discount_active = 'Y'
      AND sm.sm_type = 'AIR'
    GROUP BY i.i_item_sk, i.i_product_name, hd.hd_demo_sk, hd.hd_income_band_sk
    HAVING SUM(cs.cs_net_paid) > 1000
       AND SUM(ws.ws_net_paid) > 1000
)
SELECT
    ss.i_item_sk,
    ss.i_product_name,
    ss.hd_demo_sk,
    ss.hd_income_band_sk,
    ss.cat_net_paid,
    ss.web_net_paid,
    (ss.cat_net_paid + ss.web_net_paid) AS total_net_paid,
    RANK() OVER (PARTITION BY ss.hd_income_band_sk ORDER BY (ss.cat_net_paid + ss.web_net_paid) DESC) AS rank_within_income_band
FROM sales_summary ss
WHERE EXISTS (
    SELECT 1
    FROM store_returns sr
    WHERE sr.sr_item_sk = ss.i_item_sk
      AND sr.sr_hdemo_sk = ss.hd_demo_sk
      AND sr.sr_return_quantity > 0
)
ORDER BY total_net_paid DESC
LIMIT 100
