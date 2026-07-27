WITH returns_agg AS (
    SELECT
        sr_store_sk,
        sr_item_sk,
        SUM(sr_return_amt) AS total_return_amt,
        COUNT(*) AS cnt_returns,
        SUM(sr_refunded_cash) AS total_refunded_cash
    FROM store_returns
    WHERE sr_return_quantity > 0
      AND sr_refunded_cash > 20
      AND sr_returned_date_sk BETWEEN 2451300 AND 2452000
    GROUP BY sr_store_sk, sr_item_sk
),
sales_agg AS (
    SELECT
        ws.ws_item_sk,
        ws.ws_sold_time_sk,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(*) AS cnt_sales
    FROM web_sales ws
    JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE p.p_cost BETWEEN 100 AND 500
      AND i.i_current_price > 20
    GROUP BY ws.ws_item_sk, ws.ws_sold_time_sk
)
SELECT
    s.s_store_id,
    i.i_item_id,
    i.i_color,
    r.total_return_amt,
    r.cnt_returns,
    sa.total_net_profit,
    sa.total_quantity,
    ROW_NUMBER() OVER (PARTITION BY s.s_store_id ORDER BY sa.total_net_profit DESC) AS profit_rank,
    SUM(sa.total_net_profit) OVER (PARTITION BY s.s_store_id ORDER BY sa.total_net_profit ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
FROM returns_agg r
JOIN store s ON r.sr_store_sk = s.s_store_sk
JOIN item i ON r.sr_item_sk = i.i_item_sk
JOIN sales_agg sa ON sa.ws_item_sk = i.i_item_sk
JOIN time_dim td ON sa.ws_sold_time_sk = td.t_time_sk
WHERE s.s_floor_space > 5000
  AND td.t_hour BETWEEN 9 AND 17
  AND i.i_brand_id IN (10, 20, 30)
  AND i.i_color IN ('pink', 'olive')
GROUP BY
    s.s_store_id,
    i.i_item_id,
    i.i_color,
    r.total_return_amt,
    r.cnt_returns,
    sa.total_net_profit,
    sa.total_quantity,
    s.s_floor_space,
    td.t_hour
HAVING SUM(sa.total_net_profit) > 2000
ORDER BY cumulative_profit DESC
LIMIT 100
