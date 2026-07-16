WITH
year_range AS (
    SELECT year
    FROM UNNEST(sequence(1998, 2002)) AS t(year)
),
store_agg AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        d.d_year,
        SUM(ss.ss_net_profit) AS store_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS store_orders,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year IN (SELECT year FROM year_range)
    GROUP BY ss.ss_customer_sk, d.d_year
),
web_agg AS (
    SELECT
        ws.ws_bill_customer_sk AS cust_sk,
        d.d_year,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT ws.ws_order_number) AS web_orders,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year IN (SELECT year FROM year_range)
    GROUP BY ws.ws_bill_customer_sk, d.d_year
),
catalog_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        d.d_year,
        SUM(cs.cs_net_profit) AS catalog_profit,
        COUNT(DISTINCT cs.cs_order_number) AS catalog_orders,
        SUM(cs.cs_quantity) AS catalog_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year IN (SELECT year FROM year_range)
    GROUP BY cs.cs_bill_customer_sk, d.d_year
),
customer_base AS (
    SELECT
        c.c_customer_sk,
        c.c_first_name,
        c.c_last_name,
        COALESCE(c.c_preferred_cust_flag, 'N') AS pref_flag,
        MIN(c.c_email_address) AS email
    FROM customer c
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name, COALESCE(c.c_preferred_cust_flag, 'N')
),
combined_sales AS (
    SELECT
        COALESCE(sa.cust_sk, wa.cust_sk, ca.cust_sk) AS cust_sk,
        COALESCE(sa.d_year, wa.d_year, ca.d_year) AS d_year,
        COALESCE(sa.store_profit, 0) AS store_profit,
        COALESCE(wa.web_profit, 0) AS web_profit,
        COALESCE(ca.catalog_profit, 0) AS catalog_profit,
        COALESCE(sa.store_orders, 0) AS store_orders,
        COALESCE(wa.web_orders, 0) AS web_orders,
        COALESCE(ca.catalog_orders, 0) AS catalog_orders,
        COALESCE(sa.store_quantity, 0) AS store_quantity,
        COALESCE(wa.web_quantity, 0) AS web_quantity,
        COALESCE(ca.catalog_quantity, 0) AS catalog_quantity
    FROM store_agg sa
    FULL OUTER JOIN web_agg wa ON sa.cust_sk = wa.cust_sk AND sa.d_year = wa.d_year
    FULL OUTER JOIN catalog_agg ca ON COALESCE(sa.cust_sk, wa.cust_sk) = ca.cust_sk AND COALESCE(sa.d_year, wa.d_year) = ca.d_year
),
sales_with_return AS (
    SELECT
        cb.c_customer_sk AS cust_sk,
        cb.c_first_name,
        cb.c_last_name,
        cb.pref_flag,
        cb.email,
        cs.d_year,
        cs.store_profit,
        cs.web_profit,
        cs.catalog_profit,
        cs.store_quantity,
        cs.web_quantity,
        cs.catalog_quantity,
        cs.store_orders,
        cs.web_orders,
        cs.catalog_orders,
        (cs.store_profit + cs.web_profit + cs.catalog_profit) AS total_profit,
        (cs.store_quantity + cs.web_quantity + cs.catalog_quantity) AS total_quantity,
        (cs.store_orders + cs.web_orders + cs.catalog_orders) AS total_orders
    FROM customer_base cb
    LEFT JOIN combined_sales cs ON cb.c_customer_sk = cs.cust_sk
),
cust_returns AS (
    SELECT
        cr.cr_returning_customer_sk AS cust_sk,
        d.d_year,
        SUM(cr.cr_net_loss) AS total_return_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year IN (SELECT year FROM year_range)
    GROUP BY cr.cr_returning_customer_sk, d.d_year
),
final_combined AS (
    SELECT
        s.cust_sk,
        s.c_first_name,
        s.c_last_name,
        s.pref_flag,
        s.email,
        s.d_year,
        s.total_profit,
        s.total_quantity,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit_adj
    FROM
        sales_with_return s
        LEFT JOIN cust_returns r ON s.cust_sk = r.cust_sk AND s.d_year = r.d_year
),
ranked AS (
    SELECT
        f.*,
        ROW_NUMBER() OVER (PARTITION BY f.d_year ORDER BY f.net_profit_adj DESC) AS profit_rank,
        ROUND(f.net_profit_adj / NULLIF(f.total_quantity, 0), 2) AS profit_per_item,
        CONCAT(f.c_first_name, ' ', f.c_last_name) AS full_name,
        CASE WHEN f.pref_flag = 'Y' THEN 'Preferred' ELSE 'Regular' END AS customer_type,
        (SELECT AVG(s2.total_profit) FROM sales_with_return s2 WHERE s2.cust_sk = f.cust_sk) AS avg_customer_profit,
        SUM(f.net_profit_adj) OVER (PARTITION BY f.d_year ORDER BY f.net_profit_adj DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit,
        LAG(f.net_profit_adj) OVER (PARTITION BY f.d_year ORDER BY f.net_profit_adj DESC) AS prev_profit,
        CASE
            WHEN LAG(f.net_profit_adj) OVER (PARTITION BY f.d_year ORDER BY f.net_profit_adj DESC) IS NULL THEN NULL
            WHEN LAG(f.net_profit_adj) OVER (PARTITION BY f.d_year ORDER BY f.net_profit_adj DESC) = 0 THEN NULL
            ELSE ROUND(
                (f.net_profit_adj - LAG(f.net_profit_adj) OVER (PARTITION BY f.d_year ORDER BY f.net_profit_adj DESC))
                / LAG(f.net_profit_adj) OVER (PARTITION BY f.d_year ORDER BY f.net_profit_adj DESC) * 100,
                2
            )
        END AS profit_change_pct,
        ROUND(f.net_profit_adj * 100.0 / SUM(f.net_profit_adj) OVER (PARTITION BY f.d_year), 2) AS profit_pct_of_total
    FROM
        final_combined f
)
SELECT
    profit_rank,
    d_year,
    full_name,
    email,
    customer_type,
    net_profit_adj,
    profit_per_item,
    avg_customer_profit,
    cumulative_profit,
    profit_change_pct,
    profit_pct_of_total
FROM
    ranked
WHERE
    profit_rank <= 20
UNION ALL
SELECT
    NULL AS profit_rank,
    d_year,
    'TOTAL' AS full_name,
    NULL AS email,
    NULL AS customer_type,
    SUM(net_profit_adj) AS net_profit_adj,
    ROUND(SUM(net_profit_adj) / NULLIF(SUM(total_quantity), 0), 2) AS profit_per_item,
    NULL AS avg_customer_profit,
    SUM(cumulative_profit) AS cumulative_profit,
    NULL AS profit_change_pct,
    100.0 AS profit_pct_of_total
FROM
    ranked
GROUP BY
    d_year,
    profit_rank,
    full_name,
    email,
    customer_type,
    avg_customer_profit,
    cumulative_profit,
    profit_change_pct,
    profit_pct_of_total
ORDER BY
    d_year,
    profit_rank
