WITH returns_agg AS (
    SELECT
        d.d_date,
        i.i_item_sk,
        SUM(cr.cr_return_quantity) AS total_return_quantity,
        SUM(cr.cr_return_amount)   AS total_return_amount
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_date, i.i_item_sk
),
sales_agg AS (
    SELECT
        d.d_date,
        s.s_store_sk,
        i.i_item_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        COUNT(DISTINCT ss.ss_ticket_number)               AS sales_transactions,
        SUM(ss.ss_quantity)                               AS total_sales_quantity,
        SUM(ss.ss_sales_price * ss.ss_quantity)           AS total_sales_amount,
        SUM(ss.ss_net_profit)                             AS total_net_profit
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ss.ss_item_sk = i.i_item_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year = 2022
      AND s.s_state = 'CA'
    GROUP BY
        d.d_date,
        s.s_store_sk,
        i.i_item_sk,
        s.s_store_name,
        s.s_city,
        s.s_state
)
SELECT
    sa.d_date,
    i.i_item_id,
    i.i_product_name,
    sa.s_store_name,
    sa.s_city,
    sa.s_state,
    sa.sales_transactions,
    sa.total_sales_quantity,
    sa.total_sales_amount,
    sa.total_net_profit,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_amount, 0)   AS total_return_amount,
    (sa.total_sales_amount - COALESCE(r.total_return_amount, 0)) AS net_sales_after_returns,
    CASE
        WHEN sa.total_sales_quantity > 0
        THEN COALESCE(r.total_return_quantity, 0) * 100.0 / sa.total_sales_quantity
        ELSE NULL
    END AS return_rate_percent,
    i.i_wholesale_cost,
    i.i_current_price
FROM sales_agg sa
LEFT JOIN returns_agg r
    ON sa.d_date = r.d_date
   AND sa.i_item_sk = r.i_item_sk
JOIN item i
    ON sa.i_item_sk = i.i_item_sk
ORDER BY net_sales_after_returns DESC
LIMIT 100
