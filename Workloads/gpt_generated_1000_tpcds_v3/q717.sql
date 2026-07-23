WITH promo_items AS (
    SELECT i.i_item_sk
    FROM promotion p
    JOIN item i ON p.p_item_sk = i.i_item_sk
    WHERE p.p_discount_active = 'Y'
),
raw_returns AS (
    SELECT
        'Store' AS channel,
        d.d_date AS return_date,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE s.s_state = 'CA'
      AND d.d_year = 2001
      AND i.i_item_sk IN (SELECT i_item_sk FROM promo_items)
    UNION ALL
    SELECT
        'Web' AS channel,
        d.d_date AS return_date,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN web_sales ws ON wr.wr_order_number = ws.ws_order_number
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
      AND i.i_item_sk IN (SELECT i_item_sk FROM promo_items)
)
SELECT
    channel,
    return_date,
    return_amount,
    net_loss,
    SUM(return_amount) OVER (PARTITION BY channel ORDER BY return_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_return_amount,
    (SELECT COUNT(*) FROM promo_items) AS promo_item_count
FROM raw_returns
ORDER BY channel, return_date
LIMIT 100
