WITH combined AS (
    -- Store returns aggregation
    SELECT
        d.d_year AS return_year,
        'store' AS entity_type,
        SUM(sr.sr_return_amt_inc_tax) AS total_return_amount,
        CASE WHEN SUM(sr.sr_net_loss) > 1000 THEN 'Y' ELSE 'N' END AS high_loss_flag,
        ca_counts.cust_count AS store_customer_count,
        (
            SELECT AVG(cr3.cr_return_amount)
            FROM catalog_returns cr3
            JOIN date_dim d3 ON cr3.cr_returned_date_sk = d3.d_date_sk
            WHERE d3.d_year = d.d_year
        ) AS avg_catalog_ret_amount
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON sr.sr_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON sr.sr_addr_sk = ca.ca_address_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    LEFT JOIN LATERAL (
        SELECT COUNT(DISTINCT c2.c_customer_sk) AS cust_count
        FROM customer c2
        JOIN customer_address ca2 ON c2.c_current_addr_sk = ca2.ca_address_sk
        WHERE ca2.ca_city = s.s_city
    ) ca_counts ON TRUE
    GROUP BY d.d_year, ca_counts.cust_count
    HAVING SUM(sr.sr_return_amt_inc_tax) > 5000

    UNION

    -- Catalog returns aggregation
    SELECT
        d.d_year AS return_year,
        'catalog' AS entity_type,
        SUM(cr.cr_return_amt_inc_tax) AS total_return_amount,
        CASE WHEN SUM(cr.cr_net_loss) > 2000 THEN 'Y' ELSE 'N' END AS high_loss_flag,
        wa_counts.cust_count AS warehouse_customer_count,
        (
            SELECT AVG(sr2.sr_return_amt_inc_tax)
            FROM store_returns sr2
            JOIN date_dim d2 ON sr2.sr_returned_date_sk = d2.d_date_sk
            WHERE d2.d_year = d.d_year
        ) AS avg_store_ret_amount
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN LATERAL (
        SELECT COUNT(DISTINCT c3.c_customer_sk) AS cust_count
        FROM customer c3
        JOIN customer_address ca3 ON c3.c_current_addr_sk = ca3.ca_address_sk
        WHERE ca3.ca_state = w.w_state
    ) wa_counts ON TRUE
    GROUP BY d.d_year, wa_counts.cust_count
    HAVING SUM(cr.cr_return_amt_inc_tax) > 8000
)
SELECT *
FROM combined
ORDER BY total_return_amount DESC
OFFSET 5
LIMIT 100
