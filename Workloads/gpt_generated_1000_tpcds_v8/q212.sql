WITH sales AS (
    SELECT
        cs_order_number,
        cs_sold_date_sk,
        cs_bill_customer_sk,
        cs_bill_addr_sk,
        cs_warehouse_sk,
        cs_item_sk,
        cs_net_profit,
        cs_quantity,
        cs_sales_price,
        cs_ship_mode_sk
    FROM catalog_sales TABLESAMPLE BERNOULLI (10)
    WHERE cs_sold_date_sk BETWEEN 2450000 AND 2453000               -- predicate 1
      AND cs_quantity > 0                                          -- predicate 2
      AND cs_sales_price > 100                                     -- predicate 3
      AND cs_net_profit > 0                                        -- predicate 4
      AND cs_ship_mode_sk IN (1, 2, 3)                             -- predicate 5
),
returns AS (
    SELECT DISTINCT wr_order_number
    FROM web_returns
    WHERE wr_return_quantity > 0
      AND wr_reason_sk IN (
          SELECT r_reason_sk
          FROM reason
          WHERE r_reason_desc LIKE '%defect%'
      )
),
orders_no_return AS (
    SELECT cs_order_number FROM sales
    EXCEPT
    SELECT wr_order_number FROM returns
),
sales_no_return AS (
    SELECT s.*
    FROM sales s
    JOIN orders_no_return on s.cs_order_number = orders_no_return.cs_order_number
),
joined AS (
    SELECT
        s.cs_order_number,
        s.cs_sold_date_sk,
        s.cs_net_profit,
        s.cs_quantity,
        s.cs_sales_price,
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        ca.ca_state,
        w.w_warehouse_name,
        w.w_state AS warehouse_state,
        inv.inv_quantity_on_hand,
        r.r_reason_desc,
        ROW_NUMBER() OVER (PARTITION BY ca.ca_state ORDER BY s.cs_net_profit DESC) AS state_profit_rank
    FROM sales_no_return s
    JOIN customer c ON s.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON s.cs_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w ON s.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN inventory inv
        ON inv.inv_warehouse_sk = w.w_warehouse_sk
        AND inv.inv_item_sk = s.cs_item_sk
        AND inv.inv_date_sk = s.cs_sold_date_sk
    LEFT JOIN web_returns wr
        ON wr.wr_refunded_customer_sk = c.c_customer_sk
    LEFT JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    WHERE ca.ca_state IN ('CA', 'TX', 'NY', 'FL', 'WA')                 -- predicate 6
      AND w.w_state IN ('CA', 'TX')                                    -- predicate 7
      AND s.cs_net_profit > 50                                         -- predicate 8
      AND inv.inv_quantity_on_hand IS NOT NULL                         -- predicate 9
      AND (r.r_reason_desc IS NULL OR r.r_reason_desc NOT LIKE '%damage%') -- predicate 10
),
final AS (
    SELECT *
    FROM joined
    WHERE state_profit_rank <= 5
)
SELECT
    cs_order_number,
    cs_sold_date_sk,
    c_first_name,
    c_last_name,
    ca_state,
    w_warehouse_name,
    cs_net_profit,
    cs_quantity,
    cs_sales_price,
    inv_quantity_on_hand,
    state_profit_rank
FROM final
ORDER BY ca_state, state_profit_rank
LIMIT 100
