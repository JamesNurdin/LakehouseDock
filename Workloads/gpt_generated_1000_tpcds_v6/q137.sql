WITH joined_data AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_time_sk,
        sr.sr_item_sk,
        sr.sr_customer_sk,
        sr.sr_cdemo_sk,
        sr.sr_store_sk,
        sr.sr_return_amt,
        sr.sr_refunded_cash,
        t.t_hour,
        i.i_product_name,
        i.i_current_price,
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        inv.inv_quantity_on_hand,
        ws.ws_net_profit
    FROM store_returns AS sr
    JOIN time_dim AS t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item AS i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store AS s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer AS c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics AS cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN inventory AS inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN web_sales AS ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND i.i_current_price > 50
      AND s.s_state = 'CA'
      AND inv.inv_quantity_on_hand > 200
      AND cd.cd_gender = 'M'
      AND sr.sr_refunded_cash > 100
)
SELECT DISTINCT
    store_id,
    store_name,
    state,
    product_name,
    hour,
    return_amt,
    net_profit,
    CASE
        WHEN return_amt > 500 THEN 'High'
        WHEN return_amt > 200 THEN 'Medium'
        ELSE 'Low'
    END AS return_category,
    ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY return_amt DESC) AS rn_return_amt,
    RANK() OVER (PARTITION BY state ORDER BY net_profit DESC) AS rank_state_profit
FROM (
    SELECT
        s.s_store_id AS store_id,
        s.s_store_name AS store_name,
        s.s_state AS state,
        i.i_product_name AS product_name,
        t.t_hour AS hour,
        sr.sr_return_amt AS return_amt,
        ws.ws_net_profit AS net_profit
    FROM store_returns AS sr
    JOIN time_dim AS t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN item AS i
        ON sr.sr_item_sk = i.i_item_sk
    JOIN store AS s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN customer AS c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN customer_demographics AS cd
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN inventory AS inv
        ON inv.inv_item_sk = i.i_item_sk
    JOIN web_sales AS ws
        ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_sold_time_sk = t.t_time_sk
    WHERE t.t_hour BETWEEN 9 AND 17
      AND i.i_current_price > 50
      AND s.s_state = 'CA'
      AND inv.inv_quantity_on_hand > 200
      AND cd.cd_gender = 'M'
      AND sr.sr_refunded_cash > 100
) AS sub
ORDER BY rn_return_amt, rank_state_profit
LIMIT 100
