WITH joined AS (
    SELECT
        cr.cr_item_sk,
        cr.cr_returning_addr_sk,
        cr.cr_return_amount,
        cs.cs_sales_price,
        cs.cs_net_profit,
        cs.cs_ext_list_price
    FROM catalog_returns cr
    JOIN catalog_sales cs
        ON cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_order_number = cs.cs_order_number
    WHERE cr.cr_returning_addr_sk IN (3431573, 562952, 3744334)
      AND cr.cr_return_amount > 150
      AND cs.cs_sales_price BETWEEN 10 AND 200
      AND EXISTS (
          SELECT 1
          FROM catalog_sales cs2
          WHERE cs2.cs_item_sk = cr.cr_item_sk
            AND cs2.cs_ext_list_price > 5000
      )
),
agg1 AS (
    SELECT
        cr_item_sk,
        cr_returning_addr_sk,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cs_net_profit) AS total_net_profit,
        COUNT(*) AS transaction_cnt
    FROM joined
    GROUP BY cr_item_sk, cr_returning_addr_sk
),
final AS (
    SELECT
        cr_item_sk,
        cr_returning_addr_sk,
        total_return_amount,
        total_net_profit,
        transaction_cnt,
        total_net_profit / NULLIF(total_return_amount, 0) AS profit_per_return_amount
    FROM agg1
    WHERE total_return_amount > 500
)
SELECT
    cr_item_sk,
    cr_returning_addr_sk,
    total_return_amount,
    total_net_profit,
    transaction_cnt,
    profit_per_return_amount
FROM final
ORDER BY profit_per_return_amount DESC
LIMIT 100
