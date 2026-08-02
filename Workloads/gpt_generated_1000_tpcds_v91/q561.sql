/*
  Goal: Create a combined view of per‑customer web‑sales profit and catalog‑return amounts, rank each customer within the combined view, and show the total number of refunds per customer.
*/
WITH sales_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        'web_sales' AS source,
        SUM(ws.ws_net_paid) AS amount,
        MAX(wp.wp_rec_start_date) AS reference_date
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE wp.wp_rec_start_date >= DATE '2000-01-01'
      AND wp.wp_rec_start_date < DATE '2001-01-01'
    GROUP BY c.c_customer_sk, c.c_customer_id
),
distinct_returns AS (
    SELECT DISTINCT
        cr.cr_refunded_customer_sk,
        cr.cr_return_amt_inc_tax
    FROM catalog_returns cr
    WHERE cr.cr_return_amt_inc_tax > 0
),
returns_summary AS (
    SELECT
        c.c_customer_sk,
        c.c_customer_id,
        'catalog_returns' AS source,
        SUM(dr.cr_return_amt_inc_tax) AS amount,
        CAST(NULL AS DATE) AS reference_date
    FROM distinct_returns dr
    JOIN customer c ON dr.cr_refunded_customer_sk = c.c_customer_sk
    GROUP BY c.c_customer_sk, c.c_customer_id
),
combined AS (
    SELECT c_customer_sk, c_customer_id, source, amount, reference_date
    FROM sales_summary
    UNION
    SELECT c_customer_sk, c_customer_id, source, amount, reference_date
    FROM returns_summary
)
SELECT
    cm.c_customer_id,
    cm.source,
    cm.amount,
    cm.reference_date,
    ROW_NUMBER() OVER (PARTITION BY cm.c_customer_id ORDER BY cm.amount DESC) AS rank_per_customer,
    (SELECT COUNT(*)
     FROM catalog_returns cr2
     WHERE cr2.cr_refunded_customer_sk = cm.c_customer_sk) AS total_refunds
FROM combined cm
ORDER BY cm.amount DESC
LIMIT 100
