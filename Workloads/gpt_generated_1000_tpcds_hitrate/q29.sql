WITH catalog_data AS (
    SELECT
        cs.cs_order_number          AS order_number,
        cs.cs_net_paid              AS net_paid,
        i.i_item_id                 AS item_id,
        c.c_customer_id             AS customer_id,
        td.t_hour                   AS hour_of_day,
        i.i_item_desc               AS item_description,
        w.word                      AS word
    FROM catalog_sales cs
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN time_dim td
        ON cs.cs_sold_time_sk = td.t_time_sk
    CROSS JOIN LATERAL (
        SELECT word
        FROM UNNEST(split(i.i_item_desc, ' ')) AS t(word)
    ) w
    WHERE cs.cs_sold_date_sk BETWEEN 2451480 AND 2451545
      AND i.i_category = 'Electronics'
),
web_data AS (
    SELECT
        ws.ws_order_number          AS order_number,
        ws.ws_net_paid              AS net_paid,
        i.i_item_id                 AS item_id,
        c.c_customer_id             AS customer_id,
        td.t_hour                   AS hour_of_day,
        i.i_item_desc               AS item_description,
        w.word                      AS word
    FROM web_sales ws
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN time_dim td
        ON ws.ws_sold_time_sk = td.t_time_sk
    CROSS JOIN LATERAL (
        SELECT word
        FROM UNNEST(split(i.i_item_desc, ' ')) AS t(word)
    ) w
    WHERE ws.ws_sold_date_sk BETWEEN 2451480 AND 2451545
      AND i.i_category = 'Electronics'
)
SELECT
    order_number,
    net_paid,
    item_id,
    customer_id,
    hour_of_day,
    word
FROM catalog_data
UNION ALL
SELECT
    order_number,
    net_paid,
    item_id,
    customer_id,
    hour_of_day,
    word
FROM web_data
ORDER BY net_paid DESC
LIMIT 100
