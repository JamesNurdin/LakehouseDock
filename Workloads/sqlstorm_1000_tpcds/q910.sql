WITH sales_union AS (
    SELECT
        cs.cs_call_center_sk AS call_center_sk,
        d.d_year,
        d.d_date,
        cs.cs_net_profit AS profit,
        cs.cs_net_paid AS paid,
        cs.cs_quantity AS quantity,
        'catalog' AS channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT
        NULL AS call_center_sk,
        d.d_year,
        d.d_date,
        ws.ws_net_profit AS profit,
        ws.ws_net_paid AS paid,
        ws.ws_quantity AS quantity,
        'web' AS channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    UNION ALL
    SELECT
        NULL AS call_center_sk,
        d.d_year,
        d.d_date,
        ss.ss_net_profit AS profit,
        ss.ss_net_paid AS paid,
        ss.ss_quantity AS quantity,
        'store' AS channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
),
sales_agg AS (
    SELECT
        call_center_sk,
        d_year,
        SUM(profit) AS total_profit,
        SUM(paid) AS total_paid,
        SUM(quantity) AS total_quantity,
        COUNT(*) AS transaction_count
    FROM sales_union
    GROUP BY call_center_sk, d_year
),
customer_purchases AS (
    SELECT
        cs.cs_call_center_sk AS call_center_sk,
        cs.cs_bill_customer_sk AS customer_sk,
        SUM(cs.cs_net_paid) AS customer_paid,
        ROW_NUMBER() OVER (PARTITION BY cs.cs_call_center_sk ORDER BY SUM(cs.cs_net_paid) DESC) AS rn
    FROM catalog_sales cs
    GROUP BY cs.cs_call_center_sk, cs.cs_bill_customer_sk
),
top_customers AS (
    SELECT
        call_center_sk,
        customer_sk,
        customer_paid
    FROM customer_purchases
    WHERE rn = 1
),
call_center_info AS (
    SELECT
        cc.*,
        COALESCE(s.total_profit, 0) AS total_profit,
        COALESCE(s.total_paid, 0) AS total_paid,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        p.customer_sk,
        p.customer_paid,
        CONCAT(cc.cc_name, ' - ', COALESCE(cc.cc_city, 'UNKNOWN')) AS full_name,
        COALESCE(cc.cc_gmt_offset, 0) AS gmt_offset,
        CASE WHEN cc.cc_closed_date_sk IS NULL THEN 'OPEN' ELSE 'CLOSED' END AS call_center_status,
        (
            SELECT MAX(d2.d_date)
            FROM catalog_sales cs2
            JOIN date_dim d2 ON cs2.cs_sold_date_sk = d2.d_date_sk
            WHERE cs2.cs_call_center_sk = cc.cc_call_center_sk
        ) AS latest_sale_date,
        s.d_year AS sales_year
    FROM call_center cc
    LEFT JOIN sales_agg s ON cc.cc_call_center_sk = s.call_center_sk
    LEFT JOIN top_customers p ON cc.cc_call_center_sk = p.call_center_sk
    WHERE cc.cc_employees > 0 OR cc.cc_employees IS NULL
),
ranked AS (
    SELECT
        *,
        RANK() OVER (ORDER BY total_profit DESC) AS profit_rank,
        SUM(total_profit) OVER (PARTITION BY call_center_status) AS profit_by_status,
        SUM(total_profit) OVER (ORDER BY sales_year ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit
    FROM call_center_info
)
SELECT
    r.cc_call_center_id,
    r.full_name,
    r.cc_state,
    r.cc_employees,
    r.total_profit,
    r.total_paid,
    r.total_quantity,
    r.customer_paid AS top_customer_paid,
    r.profit_rank,
    r.profit_by_status,
    r.cumulative_profit,
    r.call_center_status,
    CASE
        WHEN r.latest_sale_date IS NULL THEN 'No Sales'
        WHEN r.latest_sale_date >= DATE '2022-01-01' THEN 'Recent'
        ELSE 'Historical'
    END AS sales_recency,
    TRIM(REGEXP_REPLACE(r.full_name, '\\s+', ' ')) AS normalized_name,
    COALESCE(r.cc_tax_percentage, 0) AS tax_percentage,
    (SELECT COUNT(DISTINCT cs3.cs_bill_customer_sk)
     FROM catalog_sales cs3
     WHERE cs3.cs_call_center_sk = r.cc_call_center_sk) AS distinct_customers
FROM ranked r
WHERE r.total_profit IS NOT NULL
ORDER BY r.profit_rank
LIMIT 200
