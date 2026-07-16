WITH unified_sales AS (
    SELECT ss_sold_date_sk AS date_sk,
           ss_customer_sk AS customer_sk,
           ss_item_sk AS item_sk,
           ss_net_profit AS net_profit,
           ss_quantity AS quantity
    FROM store_sales
    UNION ALL
    SELECT cs_sold_date_sk,
           cs_bill_customer_sk,
           cs_item_sk,
           cs_net_profit,
           cs_quantity
    FROM catalog_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_bill_customer_sk,
           ws_item_sk,
           ws_net_profit,
           ws_quantity
    FROM web_sales
),
sales_with_details AS (
    SELECT us.date_sk,
           us.customer_sk,
           us.item_sk,
           us.net_profit,
           us.quantity,
           i.i_category,
           d.d_date
    FROM unified_sales us
    JOIN item i ON us.item_sk = i.i_item_sk
    JOIN date_dim d ON us.date_sk = d.d_date_sk
),
customer_daily_agg AS (
    SELECT
        swd.d_date,
        swd.customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        SUM(swd.net_profit) AS total_net_profit,
        SUM(swd.quantity) AS total_quantity
    FROM sales_with_details swd
    JOIN customer c ON swd.customer_sk = c.c_customer_sk
    GROUP BY swd.d_date, swd.customer_sk, c.c_customer_id, c.c_first_name, c.c_last_name
),
category_breakdown AS (
    SELECT
        swd.d_date,
        swd.customer_sk,
        swd.i_category,
        SUM(swd.net_profit) AS cat_net_profit,
        ROW_NUMBER() OVER (PARTITION BY swd.d_date, swd.customer_sk ORDER BY SUM(swd.net_profit) DESC) AS cat_rank
    FROM sales_with_details swd
    GROUP BY swd.d_date, swd.customer_sk, swd.i_category
),
top_categories AS (
    SELECT
        d_date,
        customer_sk,
        array_agg(i_category ORDER BY cat_net_profit DESC) AS top_categories,
        array_agg(cat_net_profit ORDER BY cat_net_profit DESC) AS top_category_profits
    FROM category_breakdown
    WHERE cat_rank <= 3
    GROUP BY d_date, customer_sk
),
ranked_customers AS (
    SELECT
        cda.*,
        ROW_NUMBER() OVER (PARTITION BY cda.d_date ORDER BY cda.total_net_profit DESC) AS rn,
        tc.top_categories,
        tc.top_category_profits
    FROM customer_daily_agg cda
    LEFT JOIN top_categories tc
      ON cda.d_date = tc.d_date AND cda.customer_sk = tc.customer_sk
)
SELECT
    d_date,
    c_customer_id,
    c_first_name,
    c_last_name,
    total_net_profit,
    total_quantity,
    top_categories,
    top_category_profits
FROM ranked_customers
WHERE rn <= 10
ORDER BY d_date, total_net_profit DESC
