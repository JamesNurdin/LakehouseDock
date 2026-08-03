WITH filtered_items AS (
    SELECT i_item_sk,
           i_item_id,
           i_category,
           i_class
    FROM   item
    WHERE  i_category IN ('sports-apparel', 'hockey')
),
web_part AS (
    SELECT
        CAST('web' AS VARCHAR)                                   AS transaction_type,
        ws.ws_sold_date_sk                                        AS transaction_date_sk,
        c.c_customer_id                                           AS customer_id,
        i.i_item_id                                               AS item_id,
        CASE WHEN ws.ws_net_profit > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        ws.ws_net_profit                                          AS net_amount,
        t.token                                                   AS url_token,
        LAG(ws.ws_net_profit) OVER (
            PARTITION BY ws.ws_bill_customer_sk
            ORDER BY ws.ws_sold_date_sk
        )                                                         AS lag_net_profit
    FROM   web_sales ws
    JOIN   filtered_items i
           ON ws.ws_item_sk = i.i_item_sk
    JOIN   customer c
           ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN   household_demographics hd
           ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN   income_band ib
           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN   web_page wp
           ON ws.ws_web_page_sk = wp.wp_web_page_sk
    CROSS JOIN UNNEST(split(wp.wp_url, '/')) AS t (token)
    WHERE  ws.ws_ext_ship_cost > 100
      AND  ws.ws_sold_date_sk BETWEEN 2450000 AND 2450150
),
store_part AS (
    SELECT
        CAST('store' AS VARCHAR)                                 AS transaction_type,
        sr.sr_returned_date_sk                                   AS transaction_date_sk,
        c.c_customer_id                                          AS customer_id,
        i.i_item_id                                              AS item_id,
        CASE WHEN sr.sr_net_loss < 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        -sr.sr_net_loss                                          AS net_amount,
        CAST(NULL AS VARCHAR)                                    AS url_token,
        CAST(NULL AS DOUBLE)                                     AS lag_net_profit
    FROM   store_returns sr
    JOIN   filtered_items i
           ON sr.sr_item_sk = i.i_item_sk
    JOIN   customer c
           ON sr.sr_customer_sk = c.c_customer_sk
    JOIN   household_demographics hd
           ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN   income_band ib
           ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN   reason r
           ON sr.sr_reason_sk = r.r_reason_sk
    WHERE  sr.sr_return_quantity > 1
)
SELECT *
FROM   (
    SELECT * FROM web_part
    UNION ALL
    SELECT * FROM store_part
) combined
ORDER BY transaction_date_sk DESC
LIMIT 100
