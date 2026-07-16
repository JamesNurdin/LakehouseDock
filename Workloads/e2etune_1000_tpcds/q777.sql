WITH sales_agg AS (
    SELECT
        ws.ws_item_sk AS ws_item_sk,
        i.i_class AS i_class,
        sm.sm_type AS sm_type,
        SUM(ws.ws_net_paid_inc_ship_tax) AS total_sales,
        SUM(ws.ws_quantity) AS total_quantity_sold,
        COUNT(DISTINCT ws.ws_order_number) AS distinct_orders
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN ship_mode sm ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country = 'United States'
      AND ws.ws_sold_date_sk BETWEEN 2450000 AND 2450999
      AND sm.sm_type <> 'AIR'
    GROUP BY ws.ws_item_sk, i.i_class, sm.sm_type
),
returns_agg AS (
    SELECT
        sr.sr_item_sk AS sr_item_sk,
        i.i_class AS i_class,
        s.s_state AS s_state,
        SUM(sr.sr_net_loss) AS total_returns,
        SUM(sr.sr_return_quantity) AS total_quantity_returned,
        COUNT(DISTINCT sr.sr_ticket_number) AS distinct_returns
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    WHERE c.c_birth_country = 'United States'
      AND sr.sr_returned_date_sk BETWEEN 2450000 AND 2450999
      AND s.s_state = 'CA'
    GROUP BY sr.sr_item_sk, i.i_class, s.s_state
)
SELECT
    s_agg.i_class,
    s_agg.sm_type,
    r_agg.s_state,
    s_agg.total_sales,
    COALESCE(r_agg.total_returns, 0) AS total_returns,
    s_agg.total_sales - COALESCE(r_agg.total_returns, 0) AS net_profit,
    s_agg.total_quantity_sold,
    COALESCE(r_agg.total_quantity_returned, 0) AS total_quantity_returned,
    s_agg.total_quantity_sold - COALESCE(r_agg.total_quantity_returned, 0) AS net_quantity,
    s_agg.distinct_orders,
    COALESCE(r_agg.distinct_returns, 0) AS distinct_returns
FROM sales_agg s_agg
LEFT JOIN returns_agg r_agg
    ON s_agg.ws_item_sk = r_agg.sr_item_sk
WHERE (s_agg.total_sales - COALESCE(r_agg.total_returns, 0)) > 0
ORDER BY net_profit DESC
LIMIT 10
