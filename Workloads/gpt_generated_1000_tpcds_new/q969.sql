WITH
sr_sample AS (
    SELECT *
    FROM store_returns TABLESAMPLE BERNOULLI (10)
),
ws AS (
    SELECT *
    FROM web_sales
),
wr AS (
    SELECT *
    FROM web_returns
),
cust AS (
    SELECT *
    FROM customer
),
addr AS (
    SELECT *
    FROM customer_address
),
itm AS (
    SELECT *
    FROM item
),
t_dim AS (
    SELECT *
    FROM time_dim
),
full_combined AS (
    SELECT
        sr.sr_returned_date_sk AS sr_date_sk,
        sr.sr_customer_sk,
        wr.wr_returned_date_sk AS wr_date_sk,
        wr.wr_refunded_customer_sk
    FROM sr_sample sr
    FULL OUTER JOIN wr
        ON sr.sr_returned_date_sk = wr.wr_returned_date_sk
),
cust_union AS (
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 'bill' AS role
    FROM web_sales ws
    JOIN cust c ON ws.ws_bill_customer_sk = c.c_customer_sk
    UNION
    SELECT c.c_customer_sk, c.c_first_name, c.c_last_name, 'ship' AS role
    FROM web_sales ws
    JOIN cust c ON ws.ws_ship_customer_sk = c.c_customer_sk
),
item_intersect AS (
    SELECT sr.sr_item_sk AS item_sk
    FROM sr_sample sr
    INTERSECT
    SELECT ws.ws_item_sk
    FROM ws
),
final AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        i.i_item_id,
        i.i_category,
        SUM(sr.sr_net_loss) AS total_store_loss,
        SUM(ws.ws_net_profit) AS total_web_profit,
        COUNT(DISTINCT sr.sr_ticket_number) AS store_return_cnt,
        COUNT(DISTINCT ws.ws_order_number) AS web_sales_cnt,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_sk ORDER BY SUM(ws.ws_net_profit) DESC) AS profit_rank
    FROM sr_sample sr
    JOIN t_dim t1 ON sr.sr_return_time_sk = t1.t_time_sk
    JOIN itm i ON sr.sr_item_sk = i.i_item_sk
    JOIN cust c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN addr a_ret ON sr.sr_addr_sk = a_ret.ca_address_sk
    JOIN ws ON ws.ws_item_sk = i.i_item_sk
    JOIN t_dim t2 ON ws.ws_sold_time_sk = t2.t_time_sk
    JOIN cust c_ship ON ws.ws_ship_customer_sk = c_ship.c_customer_sk
    JOIN addr a_ship ON ws.ws_ship_addr_sk = a_ship.ca_address_sk
    LEFT JOIN wr ON wr.wr_item_sk = i.i_item_sk
                AND wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN cust_union cu ON cu.c_customer_sk = c.c_customer_sk
    LEFT JOIN full_combined fc ON fc.sr_customer_sk = c.c_customer_sk
    WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr2
        WHERE wr2.wr_order_number = ws.ws_order_number
          AND wr2.wr_return_quantity > 0
    )
    AND i.i_item_sk IN (SELECT item_sk FROM item_intersect)
    GROUP BY
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        i.i_item_id,
        i.i_category
)
SELECT *
FROM final
ORDER BY total_web_profit DESC, profit_rank
LIMIT 100
