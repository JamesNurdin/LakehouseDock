WITH ws_returns_agg AS (
    SELECT
        ws.ws_order_number,
        SUM(wr.wr_return_amt_inc_tax) AS total_return_amt_inc_tax
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
    GROUP BY ws.ws_order_number
)
SELECT
    promo_id,
    channel,
    total_profit,
    sales_cnt,
    profit_rank
FROM (
    SELECT
        p.p_promo_id AS promo_id,
        'store' AS channel,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt,
        RANK() OVER (ORDER BY SUM(ss.ss_net_profit) DESC) AS profit_rank
    FROM store_sales ss
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_channel_event = 'Y'
    GROUP BY p.p_promo_id

    UNION ALL

    SELECT
        p.p_promo_id AS promo_id,
        'web' AS channel,
        SUM(ws.ws_net_profit - COALESCE(r.total_return_amt_inc_tax, 0)) AS total_profit,
        COUNT(*) AS sales_cnt,
        RANK() OVER (ORDER BY SUM(ws.ws_net_profit - COALESCE(r.total_return_amt_inc_tax, 0)) DESC) AS profit_rank
    FROM web_sales ws
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    LEFT JOIN ws_returns_agg r
        ON ws.ws_order_number = r.ws_order_number
    WHERE p.p_channel_event = 'Y'
      AND EXISTS (
          SELECT 1
          FROM web_sales ws2
          WHERE ws2.ws_bill_cdemo_sk = ws.ws_bill_cdemo_sk
            AND ws2.ws_net_paid_inc_tax > 5000
          LIMIT 1
      )
    GROUP BY p.p_promo_id
) AS combined
ORDER BY total_profit DESC, channel
LIMIT 100
