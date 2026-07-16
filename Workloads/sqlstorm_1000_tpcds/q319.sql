WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, '') AS customer_full_name,
        ca.ca_city,
        ca.ca_state,
        d.d_year,
        SUM(COALESCE(ss.ss_net_paid, 0) + COALESCE(cs.cs_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS total_net_paid,
        SUM(COALESCE(ss.ss_net_profit, 0) + COALESCE(cs.cs_net_profit, 0) + COALESCE(ws.ws_net_profit, 0)) AS total_net_profit,
        COUNT(DISTINCT COALESCE(ss.ss_ticket_number, cs.cs_order_number, ws.ws_order_number)) AS distinct_orders,
        MAX(CASE
                WHEN ss.ss_sold_date_sk IS NOT NULL THEN ss.ss_sold_date_sk
                WHEN cs.cs_sold_date_sk IS NOT NULL THEN cs.cs_sold_date_sk
                WHEN ws.ws_sold_date_sk IS NOT NULL THEN ws.ws_sold_date_sk
            END) AS last_sold_date_sk
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON COALESCE(ss.ss_sold_date_sk, cs.cs_sold_date_sk, ws.ws_sold_date_sk) = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2003
      AND (c.c_preferred_cust_flag = 'Y' OR c.c_preferred_cust_flag IS NULL)
    GROUP BY
        c.c_customer_sk,
        c.c_customer_id,
        COALESCE(c.c_first_name, '') || ' ' || COALESCE(c.c_last_name, ''),
        ca.ca_city,
        ca.ca_state,
        d.d_year
),
ranked_customers AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS rn_year,
        RANK() OVER (ORDER BY total_net_profit DESC) AS overall_profit_rank
    FROM sales_agg
),
customer_last_purchase AS (
    SELECT
        c.c_customer_sk,
        MAX(d.d_date) AS last_purchase_date
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN catalog_sales cs ON c.c_customer_sk = cs.cs_bill_customer_sk
    LEFT JOIN web_sales ws ON c.c_customer_sk = ws.ws_bill_customer_sk
    LEFT JOIN date_dim d ON COALESCE(ss.ss_sold_date_sk, cs.cs_sold_date_sk, ws.ws_sold_date_sk) = d.d_date_sk
    GROUP BY c.c_customer_sk
),
call_center_sales AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        SUM(COALESCE(cs.cs_net_paid, 0) + COALESCE(ws.ws_net_paid, 0)) AS cc_total_net_paid,
        COUNT(DISTINCT COALESCE(cs.cs_order_number, ws.ws_order_number)) AS cc_distinct_orders,
        AVG(COALESCE(cs.cs_ext_tax, 0) + COALESCE(ws.ws_ext_tax, 0)) AS avg_tax_amount
    FROM call_center cc
    LEFT JOIN catalog_sales cs ON cc.cc_call_center_sk = cs.cs_call_center_sk
    LEFT JOIN web_sales ws ON cc.cc_call_center_sk = ws.ws_ship_mode_sk
    WHERE cc.cc_rec_end_date >= DATE '2024-10-01'
    GROUP BY cc.cc_call_center_sk, cc.cc_name
),
combined_sales AS (
    SELECT *
    FROM ranked_customers
    UNION ALL
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name || ' ' || c.c_last_name AS customer_full_name,
        ca.ca_city,
        ca.ca_state,
        d.d_year,
        0 AS total_net_paid,
        0 AS total_net_profit,
        0 AS distinct_orders,
        NULL AS last_sold_date_sk,
        NULL AS rn_year,
        NULL AS overall_profit_rank
    FROM customer c
    LEFT JOIN customer_address ca ON c.c_current_addr_sk = ca.ca_address_sk
    LEFT JOIN date_dim d ON d.d_year = 2001
    WHERE NOT EXISTS (
        SELECT 1 FROM sales_agg sa WHERE sa.c_customer_sk = c.c_customer_sk
    )
),
final_set AS (
    SELECT *
    FROM combined_sales
    INTERSECT
    SELECT *
    FROM ranked_customers
    WHERE rn_year <= 5
)
SELECT
    f.c_customer_id,
    f.customer_full_name,
    f.ca_city,
    f.ca_state,
    f.d_year,
    f.total_net_paid,
    f.total_net_profit,
    f.distinct_orders,
    CASE
        WHEN f.last_sold_date_sk IS NOT NULL THEN (SELECT d2.d_date FROM date_dim d2 WHERE d2.d_date_sk = f.last_sold_date_sk)
        ELSE NULL
    END AS last_sold_date,
    cl.last_purchase_date,
    CASE
        WHEN f.total_net_paid > 0 THEN ROUND(f.total_net_profit / f.total_net_paid * 100, 2)
        ELSE NULL
    END AS profit_margin_percent,
    cc.cc_name AS call_center_name,
    cc.cc_total_net_paid,
    cc.cc_distinct_orders,
    cc.avg_tax_amount
FROM final_set f
LEFT JOIN customer_last_purchase cl ON f.c_customer_sk = cl.c_customer_sk
LEFT JOIN call_center_sales cc ON f.c_customer_sk = cc.cc_call_center_sk
WHERE f.overall_profit_rank <= 10
ORDER BY f.overall_profit_rank, f.c_customer_id
LIMIT 100
