WITH top_customers AS (
    SELECT
        c.c_customer_sk AS customer_sk,
        c.c_first_name || ' ' || c.c_last_name AS cust_name,
        COALESCE(SUM(ss.ss_net_paid), 0) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY COALESCE(SUM(ss.ss_net_paid), 0) DESC) AS rn
    FROM customer c
    LEFT JOIN store_sales ss ON c.c_customer_sk = ss.ss_customer_sk
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY c.c_customer_sk, c.c_first_name, c.c_last_name
    HAVING COALESCE(SUM(ss.ss_net_paid), 0) > 0
),
customer_latest_return AS (
    SELECT
        cr.cr_returning_customer_sk,
        MAX(d.d_date) AS last_return_date
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    GROUP BY cr.cr_returning_customer_sk
),
sales_vs_returns AS (
    SELECT
        COALESCE(ss.ss_customer_sk, cr.cr_returning_customer_sk) AS customer_sk,
        SUM(ss.ss_net_paid) AS sales_net,
        SUM(cr.cr_return_amount) AS returns_amount,
        SUM(ss.ss_quantity) AS sales_qty,
        SUM(cr.cr_return_quantity) AS returns_qty,
        (SUM(ss.ss_net_paid) - SUM(cr.cr_return_amount)) / NULLIF(SUM(ss.ss_quantity), 0) AS net_per_item
    FROM store_sales ss
    FULL OUTER JOIN catalog_returns cr
        ON ss.ss_customer_sk = cr.cr_returning_customer_sk
        AND ss.ss_sold_date_sk = cr.cr_returned_date_sk
    GROUP BY COALESCE(ss.ss_customer_sk, cr.cr_returning_customer_sk)
),
promo_effect_top AS (
    SELECT
        p.p_promo_id AS promo_id,
        COUNT(DISTINCT ss.ss_ticket_number) AS tickets,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        AVG(ss.ss_sales_price - ss.ss_wholesale_cost) AS avg_margin,
        ROW_NUMBER() OVER (ORDER BY COUNT(DISTINCT ss.ss_ticket_number) DESC) AS rn
    FROM promotion p
    LEFT JOIN store_sales ss ON p.p_promo_sk = ss.ss_promo_sk
    LEFT JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2000
    GROUP BY p.p_promo_id
    HAVING COUNT(DISTINCT ss.ss_ticket_number) > 5
),
final AS (
    SELECT
        tc.cust_name,
        tc.total_spent,
        crl.last_return_date,
        sv.sales_net,
        sv.returns_amount,
        sv.net_per_item,
        pe.promo_id,
        pe.tickets,
        pe.total_discount,
        pe.avg_margin,
        CASE
            WHEN sv.sales_net IS NULL AND pe.tickets IS NULL THEN 'No Activity'
            WHEN sv.sales_net > 10000 THEN 'High Spender'
            ELSE 'Normal'
        END AS segment,
        ROW_NUMBER() OVER (
            PARTITION BY CASE WHEN sv.sales_net > 0 THEN 'S' ELSE 'R' END
            ORDER BY sv.sales_net DESC NULLS LAST
        ) AS rank_in_group,
        COALESCE(sv.sales_qty, 0) - COALESCE(sv.returns_qty, 0) AS net_quantity,
        CASE WHEN sv.sales_net IS NOT DISTINCT FROM 0 THEN 'Zero or Null' ELSE 'Non-Zero' END AS sales_status,
        (SELECT COUNT(*) FROM store_sales ss2 WHERE ss2.ss_customer_sk = tc.customer_sk) AS sales_txn_count,
        TIMESTAMP '2024-10-01 00:00:00' AS query_timestamp
    FROM top_customers tc
    LEFT JOIN customer_latest_return crl ON tc.customer_sk = crl.cr_returning_customer_sk
    LEFT JOIN sales_vs_returns sv ON tc.customer_sk = sv.customer_sk
    LEFT JOIN promo_effect_top pe ON pe.rn = 1
    WHERE (tc.rn <= 10 OR sv.sales_net > 5000)
      AND (pe.promo_id IS NOT NULL OR sv.sales_net IS NOT NULL)
    ORDER BY tc.total_spent DESC, sv.sales_net DESC NULLS LAST
    LIMIT 100
)
SELECT *
FROM final
WHERE segment != 'No Activity'
UNION ALL
SELECT
    'TOTAL' AS cust_name,
    SUM(total_spent) AS total_spent,
    NULL AS last_return_date,
    SUM(sales_net) AS sales_net,
    SUM(returns_amount) AS returns_amount,
    NULL AS net_per_item,
    NULL AS promo_id,
    SUM(tickets) AS tickets,
    SUM(total_discount) AS total_discount,
    AVG(avg_margin) AS avg_margin,
    NULL AS segment,
    NULL AS rank_in_group,
    NULL AS net_quantity,
    NULL AS sales_status,
    SUM(sales_txn_count) AS sales_txn_count,
    TIMESTAMP '2024-10-01 00:00:00' AS query_timestamp
FROM final
WHERE segment != 'No Activity'
