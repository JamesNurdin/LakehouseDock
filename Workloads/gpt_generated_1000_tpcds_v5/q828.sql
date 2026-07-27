WITH sr_agg AS (
    SELECT
        sr.sr_store_sk,
        sr.sr_cdemo_sk,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        COUNT(*) AS return_cnt,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN "store" s ON sr.sr_store_sk = s.s_store_sk
    WHERE cd.cd_credit_rating = 'Good'
      AND cd.cd_dep_employed_count >= 1
      AND s.s_gmt_offset = -5.00
      AND sr.sr_refunded_cash > 10
      AND sr.sr_item_sk IN (126542, 263539)
    GROUP BY sr.sr_store_sk, sr.sr_cdemo_sk
)
SELECT
    s.s_store_name,
    ws.ws_web_site_sk,
    w.web_name,
    p.p_promo_name,
    CASE
        WHEN cd.cd_credit_rating = 'Good' THEN 'A'
        WHEN cd.cd_credit_rating = 'High Risk' THEN 'C'
        ELSE 'B'
    END AS credit_category,
    SUM(ws.ws_ext_sales_price) AS total_sales,
    SUM(ws.ws_net_profit) AS total_profit,
    sr_agg.total_refunded_cash,
    sr_agg.return_cnt
FROM sr_agg
JOIN "store" s ON sr_agg.sr_store_sk = s.s_store_sk
JOIN customer_demographics cd ON sr_agg.sr_cdemo_sk = cd.cd_demo_sk
JOIN web_sales ws ON ws.ws_bill_cdemo_sk = sr_agg.sr_cdemo_sk
JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
WHERE ws.ws_quantity > 1
  AND ws.ws_net_profit > 0
  AND p.p_discount_active = 'Y'
  AND w.web_state = 'CA'
  AND EXISTS (
        SELECT 1 FROM web_sales ws2
        WHERE ws2.ws_order_number = ws.ws_order_number
          AND ws2.ws_ext_discount_amt > 5
    )
  AND sr_agg.total_refunded_cash > (
        SELECT AVG(total_refunded_cash) FROM sr_agg
    )
GROUP BY
    s.s_store_name,
    ws.ws_web_site_sk,
    w.web_name,
    p.p_promo_name,
    CASE
        WHEN cd.cd_credit_rating = 'Good' THEN 'A'
        WHEN cd.cd_credit_rating = 'High Risk' THEN 'C'
        ELSE 'B'
    END,
    sr_agg.total_refunded_cash,
    sr_agg.return_cnt
ORDER BY total_sales DESC
LIMIT 100
