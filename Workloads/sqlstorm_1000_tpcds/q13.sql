WITH unified_sales AS (
    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        i.i_item_sk AS item_sk,
        i.i_category AS category,
        i.i_class AS class,
        i.i_product_name AS product_name,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amount,
        cs.cs_quantity AS quantity,
        p.p_discount_active AS promo_active
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON cs.cs_ship_addr_sk = ca.ca_address_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2005

    UNION ALL

    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        i.i_item_sk AS item_sk,
        i.i_category AS category,
        i.i_class AS class,
        i.i_product_name AS product_name,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount_amount,
        ws.ws_quantity AS quantity,
        p.p_discount_active AS promo_active
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ws.ws_ship_addr_sk = ca.ca_address_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk AND d.d_date_sk BETWEEN p.p_start_date_sk AND p.p_end_date_sk
    WHERE d.d_year BETWEEN 2001 AND 2005

    UNION ALL

    SELECT
        d.d_year AS year,
        ca.ca_state AS state,
        i.i_item_sk AS item_sk,
        i.i_category AS category,
        i.i_class AS class,
        i.i_product_name AS product_name,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount_amount,
        ss.ss_quantity AS quantity,
        CAST(NULL AS varchar) AS promo_active
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_address ca ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2001 AND 2005
),
aggregated_sales AS (
    SELECT
        year,
        state,
        category,
        class,
        item_sk,
        product_name,
        SUM(sales_amount) AS total_sales,
        SUM(net_profit) AS total_profit,
        SUM(discount_amount) AS total_discount,
        SUM(quantity) AS total_quantity,
        SUM(CASE WHEN promo_active = 'Y' THEN 1 ELSE 0 END) AS promo_count
    FROM unified_sales
    GROUP BY
        year,
        state,
        category,
        class,
        item_sk,
        product_name
    HAVING SUM(sales_amount) > 10000
)
SELECT
    year,
    state,
    category,
    class,
    item_sk,
    product_name,
    total_sales,
    total_profit,
    total_discount,
    total_quantity,
    promo_count,
    AVG(total_profit) OVER (PARTITION BY item_sk, state ORDER BY year ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS profit_3yr_moving_avg,
    RANK() OVER (PARTITION BY year ORDER BY total_profit DESC) AS profit_rank
FROM aggregated_sales
ORDER BY year, profit_rank
LIMIT 200
