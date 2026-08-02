WITH
item_sales_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_ext_sales_price) AS item_total_sales
    FROM store_sales ss
    GROUP BY ss.ss_item_sk
),
joined_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_ext_sales_price,
        ss.ss_ext_tax,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        i.i_product_name,
        c.c_customer_id,
        s.s_store_name,
        sr.sr_return_quantity,
        ws.ws_order_number,
        i_ws.i_product_name AS ws_product_name,
        c_ws_ship.c_customer_id AS ship_cust_id,
        c_ws_bill.c_customer_id AS bill_cust_id,
        i_sr.i_product_name AS sr_product_name,
        c_sr.c_customer_id AS sr_cust_id,
        s_sr.s_store_name AS sr_store_name,
        it.item_total_sales,
        metric_name,
        metric_value
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
        AND sr.sr_item_sk = ss.ss_item_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
        AND ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN item i_ws ON ws.ws_item_sk = i_ws.i_item_sk
    JOIN customer c_ws_ship ON ws.ws_ship_customer_sk = c_ws_ship.c_customer_sk
    JOIN customer c_ws_bill ON ws.ws_bill_customer_sk = c_ws_bill.c_customer_sk
    JOIN item i_sr ON sr.sr_item_sk = i_sr.i_item_sk
    JOIN customer c_sr ON sr.sr_customer_sk = c_sr.c_customer_sk
    JOIN store s_sr ON sr.sr_store_sk = s_sr.s_store_sk
    JOIN item_sales_agg it ON it.item_sk = ss.ss_item_sk
    CROSS JOIN UNNEST(
        MAP(
            ARRAY['sales_price','tax','discount'],
            ARRAY[ss.ss_ext_sales_price, ss.ss_ext_tax, ss.ss_ext_discount_amt]
        )
    ) AS t(metric_name, metric_value)
    WHERE ss.ss_ticket_number IN (
        SELECT sr2.sr_ticket_number
        FROM store_returns sr2
        WHERE sr2.sr_net_loss > 0
    )
    AND EXISTS (
        SELECT 1
        FROM store_returns sr3
        WHERE sr3.sr_ticket_number = ss.ss_ticket_number
          AND sr3.sr_return_amt > 100
    )
),
aggregated AS (
    SELECT
        s_store_name,
        i_product_name,
        metric_name,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(metric_value) AS total_metric,
        COUNT(DISTINCT c_customer_id) AS distinct_customers,
        ss_ticket_number
    FROM joined_data
    GROUP BY
        s_store_name,
        i_product_name,
        metric_name,
        ss_ticket_number
)
SELECT
    s_store_name,
    i_product_name,
    metric_name,
    total_sales,
    total_metric,
    distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY s_store_name ORDER BY total_sales DESC) AS sales_rank,
    (
        SELECT AVG(sr5.sr_return_amt)
        FROM store_returns sr5
        WHERE sr5.sr_ticket_number = ag.ss_ticket_number
    ) AS avg_return_amount
FROM aggregated ag
ORDER BY total_sales DESC
OFFSET 0
LIMIT 100
