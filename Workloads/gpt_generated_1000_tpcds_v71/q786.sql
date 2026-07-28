WITH store_sales_agg AS (
    SELECT
        c.c_customer_id AS cust_id,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        COUNT(*) AS transaction_count,
        CASE WHEN SUM(ss.ss_ext_discount_amt) > 0 THEN 'Discounted' ELSE 'NoDiscount' END AS discount_flag
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN time_dim td ON ss.ss_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE td.t_hour BETWEEN 9 AND 17
      AND td.t_meal_time = 'Lunch'
    GROUP BY c.c_customer_id
),
web_sales_agg AS (
    SELECT
        c.c_customer_id AS cust_id,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS transaction_count,
        CASE WHEN COUNT(p.p_promo_sk) > 0 THEN 'Promo' ELSE 'NoPromo' END AS discount_flag
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN time_dim td ON ws.ws_sold_time_sk = td.t_time_sk
    LEFT JOIN promotion p ON ws.ws_promo_sk = p.p_promo_sk
    WHERE td.t_hour BETWEEN 9 AND 17
    GROUP BY c.c_customer_id
)
SELECT DISTINCT
    cust_id,
    sales_type,
    total_sales,
    transaction_count,
    discount_flag,
    CASE WHEN total_sales > (
            SELECT AVG(total_sales)
            FROM (
                SELECT total_sales FROM store_sales_agg
                UNION ALL
                SELECT total_sales FROM web_sales_agg
            ) agg
        ) THEN 'AboveAvg' ELSE 'BelowAvg' END AS sales_category
FROM (
    SELECT
        s.cust_id,
        'Store' AS sales_type,
        s.total_sales,
        s.transaction_count,
        s.discount_flag
    FROM store_sales_agg s
    JOIN customer c ON c.c_customer_id = s.cust_id
    WHERE NOT EXISTS (
        SELECT 1 FROM store_returns sr
        WHERE sr.sr_customer_sk = c.c_customer_sk
    )
    UNION ALL
    SELECT
        w.cust_id,
        'Web' AS sales_type,
        w.total_sales,
        w.transaction_count,
        w.discount_flag
    FROM web_sales_agg w
    JOIN customer c ON c.c_customer_id = w.cust_id
    WHERE NOT EXISTS (
        SELECT 1 FROM web_returns wr
        WHERE wr.wr_refunded_customer_sk = c.c_customer_sk
    )
) final
ORDER BY total_sales DESC
LIMIT 100
