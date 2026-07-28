WITH sales_agg AS (
    SELECT
        ss.ss_store_sk AS ss_store_sk,
        ss.ss_sold_date_sk AS ss_sold_date_sk,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_quantity) AS total_qty,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets
    FROM tpcds.store_sales ss
    JOIN tpcds.date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND d.d_dow IN (1, 2)
      AND d.d_current_day = 'N'
    GROUP BY ss.ss_store_sk, ss.ss_sold_date_sk
)
SELECT
    s.s_state,
    d.d_year,
    SUM(sa.total_sales) AS sum_sales,
    AVG(sa.total_sales) AS avg_sales,
    MIN(sa.total_sales) AS min_sales,
    MAX(sa.total_sales) AS max_sales,
    SUM(i.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT s.s_store_id) AS store_count
FROM sales_agg sa
JOIN tpcds.store s ON sa.ss_store_sk = s.s_store_sk
JOIN tpcds.date_dim d ON sa.ss_sold_date_sk = d.d_date_sk
JOIN tpcds.inventory i ON i.inv_date_sk = d.d_date_sk
WHERE s.s_market_id = 2
  AND s.s_suite_number = 'Suite 80  '
  AND i.inv_quantity_on_hand > 0
  AND d.d_month_seq BETWEEN 1200 AND 1300
GROUP BY GROUPING SETS (
    (s.s_state, d.d_year),
    (s.s_state),
    ()
)
ORDER BY sum_sales DESC
LIMIT 100
