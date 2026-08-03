WITH base AS (
    SELECT
        cs.cs_order_number,
        c.c_last_name,
        cd.cd_gender,
        i.i_item_id,
        i.i_size,
        w.w_warehouse_name,
        cs.cs_net_profit,
        cr.cr_return_amount,
        RANK() OVER (PARTITION BY w.w_warehouse_name ORDER BY cs.cs_net_profit DESC) AS profit_rank,
        CASE WHEN cr.cr_return_amount > 0 THEN 'Return' ELSE 'Sale' END AS transaction_type
    FROM catalog_sales cs
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i
        ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
       AND cr.cr_item_sk = i.i_item_sk
    WHERE i.i_size IN ('economy', 'medium')
      AND i.i_wholesale_cost > 5
      AND cd.cd_gender = 'M'
      AND w.w_state = 'CA'
      AND cs.cs_sales_price > 50
      AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
)
SELECT
    cs_order_number,
    c_last_name,
    cd_gender,
    i_item_id,
    i_size,
    w_warehouse_name,
    cs_net_profit,
    cr_return_amount,
    profit_rank,
    transaction_type
FROM base
WHERE cr_return_amount IS NULL
UNION DISTINCT
SELECT
    cs_order_number,
    c_last_name,
    cd_gender,
    i_item_id,
    i_size,
    w_warehouse_name,
    cs_net_profit,
    cr_return_amount,
    profit_rank,
    transaction_type
FROM base
WHERE cr_return_amount > 0
ORDER BY profit_rank ASC
LIMIT 100
