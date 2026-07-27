WITH sales_promo AS (
    SELECT
        ws.ws_order_number,
        ws.ws_net_profit,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        ws.ws_bill_hdemo_sk,
        p.p_channel_email,
        hd.hd_buy_potential
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    WHERE p.p_channel_email = 'Y'
      AND ws.ws_net_profit > 0
)
SELECT
    'Sales'      AS metric_type,
    sp.hd_buy_potential,
    COUNT(DISTINCT sp.ws_order_number)               AS cnt,
    SUM(sp.ws_net_profit)                           AS amount1,
    SUM(sp.ws_ext_sales_price)                      AS amount2
FROM sales_promo sp
GROUP BY sp.hd_buy_potential

UNION ALL

SELECT
    'Returns'    AS metric_type,
    hd.hd_buy_potential,
    COUNT(DISTINCT wr.wr_order_number)               AS cnt,
    SUM(wr.wr_net_loss)                              AS amount1,
    SUM(wr.wr_return_amt)                            AS amount2
FROM web_returns wr
JOIN web_sales ws
    ON wr.wr_order_number = ws.ws_order_number
   AND wr.wr_item_sk = ws.ws_item_sk
JOIN household_demographics hd
    ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
WHERE wr.wr_return_amt > 100
  AND EXISTS (
        SELECT 1
        FROM promotion p
        WHERE p.p_promo_sk = ws.ws_promo_sk
          AND p.p_channel_email = 'Y'
    )
GROUP BY hd.hd_buy_potential

ORDER BY metric_type, hd_buy_potential
