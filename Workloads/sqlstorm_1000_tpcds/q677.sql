WITH all_sales AS (
    SELECT
        cs.cs_bill_customer_sk AS customer_sk,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amt,
        'catalog' AS channel
    FROM catalog_sales cs
    UNION ALL
    SELECT
        ss.ss_customer_sk AS customer_sk,
        ss.ss_sold_date_sk AS sold_date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount_amt,
        'store' AS channel
    FROM store_sales ss
    UNION ALL
    SELECT
        ws.ws_bill_customer_sk AS customer_sk,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount_amt,
        'web' AS channel
    FROM web_sales ws
),
filtered_sales AS (
    SELECT
        a.customer_sk,
        a.sold_date_sk,
        a.item_sk,
        a.quantity,
        a.net_profit,
        a.discount_amt,
        a.channel,
        d.d_year AS year,
        d.d_moy AS month,
        i.i_category,
        i.i_class,
        i.i_brand,
        cd.cd_gender AS gender,
        cd.cd_marital_status AS marital_status,
        ca.ca_city AS city,
        ca.ca_state AS state,
        c.c_preferred_cust_flag AS preferred_cust_flag
    FROM all_sales a
    JOIN date_dim d ON a.sold_date_sk = d.d_date_sk
    JOIN item i ON a.item_sk = i.i_item_sk
    JOIN customer c ON a.customer_sk = c.c_customer_sk
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN customer_demographics cd ON c.c_current_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2000
),
category_agg AS (
    SELECT
        channel,
        i_category,
        year,
        month,
        gender,
        marital_status,
        preferred_cust_flag,
        city,
        state,
        SUM(quantity) AS total_quantity,
        SUM(net_profit) AS total_net_profit,
        SUM(discount_amt) AS total_discount,
        AVG(net_profit) AS avg_net_profit,
        COUNT(DISTINCT customer_sk) AS distinct_customers
    FROM filtered_sales
    GROUP BY
        channel,
        i_category,
        year,
        month,
        gender,
        marital_status,
        preferred_cust_flag,
        city,
        state
),
ranked_categories AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY channel ORDER BY total_net_profit DESC) AS category_rank
    FROM category_agg
)
SELECT
    channel,
    i_category,
    year,
    month,
    gender,
    marital_status,
    preferred_cust_flag,
    city,
    state,
    total_quantity,
    total_net_profit,
    total_discount,
    avg_net_profit,
    distinct_customers,
    category_rank
FROM ranked_categories
WHERE category_rank <= 10
ORDER BY channel, category_rank
