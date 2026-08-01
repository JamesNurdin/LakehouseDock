WITH raw_sales AS (
    SELECT
        c.c_customer_id,
        i.i_brand,
        cs.cs_sold_date_sk AS sold_date_sk,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_profit AS net_profit,
        cc.cc_state,
        cd.cd_gender,
        t.t_hour,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND c.c_birth_country = 'KOREA'
      AND i.i_color = 'Red'
      AND t.t_hour BETWEEN 9 AND 17
      AND cc.cc_suite_number LIKE 'Suite %'
    UNION ALL
    SELECT
        c.c_customer_id,
        i.i_brand,
        ws.ws_sold_date_sk AS sold_date_sk,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_profit AS net_profit,
        '' AS cc_state,
        cd.cd_gender,
        t.t_hour,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
                      AND wp.wp_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim t ON ws.ws_sold_time_sk = t.t_time_sk
    WHERE wp.wp_max_ad_count > 1
      AND c.c_birth_country = 'KOREA'
      AND i.i_color = 'Red'
      AND t.t_hour BETWEEN 9 AND 17
      AND wp.wp_rec_end_date > DATE '2000-01-01'
),
aggregated AS (
    SELECT
        c_customer_id,
        i_brand,
        sales_channel,
        SUM(sales_amount) AS total_sales,
        SUM(net_profit) AS total_profit,
        COUNT(*) AS transaction_count,
        CASE WHEN SUM(net_profit) > 0 THEN 'Profit' ELSE 'Loss' END AS profit_flag,
        GROUPING(c_customer_id) AS g_customer,
        GROUPING(i_brand) AS g_brand,
        GROUPING(sales_channel) AS g_channel
    FROM raw_sales
    GROUP BY GROUPING SETS (
        (c_customer_id, i_brand, sales_channel),
        (c_customer_id, i_brand),
        (c_customer_id),
        (i_brand),
        (sales_channel),
        ()
    )
),
final AS (
    SELECT
        c_customer_id,
        i_brand,
        sales_channel,
        total_sales,
        total_profit,
        transaction_count,
        profit_flag,
        CASE WHEN total_sales > (SELECT AVG(total_sales) FROM aggregated) THEN 'Above Avg' ELSE 'Below Avg' END AS sales_category,
        ROW_NUMBER() OVER (PARTITION BY c_customer_id, i_brand, sales_channel ORDER BY total_sales DESC) AS rn,
        (SELECT COUNT(DISTINCT c_customer_id) FROM raw_sales) AS distinct_customers
    FROM aggregated
    WHERE total_sales > 1000
)
SELECT
    c_customer_id,
    i_brand,
    sales_channel,
    total_sales,
    total_profit,
    transaction_count,
    profit_flag,
    sales_category,
    rn,
    distinct_customers
FROM final
ORDER BY total_sales DESC
LIMIT 100
