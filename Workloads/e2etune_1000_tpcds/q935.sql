WITH sales_agg AS (
    SELECT
        ca.ca_state AS state,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        COALESCE(SUM(cr.cr_net_loss), 0) AS total_return_loss,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
        AVG(cs.cs_ext_discount_amt) AS avg_discount
    FROM
        catalog_sales cs
        JOIN customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        LEFT JOIN catalog_returns cr
            ON cs.cs_item_sk = cr.cr_item_sk
            AND cs.cs_order_number = cr.cr_order_number
    WHERE
        cs.cs_ship_mode_sk = 12
        AND cs.cs_sold_date_sk BETWEEN 2450815 AND 2450845
    GROUP BY
        ca.ca_state
    HAVING
        SUM(cs.cs_net_profit) > 0
)
SELECT
    state,
    total_sales_profit,
    total_return_loss,
    total_sales_profit - total_return_loss AS net_contribution,
    distinct_items_sold,
    avg_discount,
    ROW_NUMBER() OVER (ORDER BY (total_sales_profit - total_return_loss) DESC) AS rank
FROM
    sales_agg
ORDER BY
    net_contribution DESC
LIMIT 10
