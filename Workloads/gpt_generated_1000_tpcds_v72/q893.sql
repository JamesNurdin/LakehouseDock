/*
  Goal: Identify the top stores in 2002 whose suite numbers follow the pattern "Suite <digits>", located in cities starting with "A", and that ran a promotion containing the word "Clearance". The query extracts the numeric suite identifier, categorizes stores by tax rate, aggregates net paid sales, ranks stores within each state, and limits the result to the top 100 rows.
*/
WITH sales_by_store AS (
    SELECT
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_suite_number,
        s.s_tax_percentage,
        p.p_promo_name,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(*) AS txn_count
    FROM store_sales ss
    INNER JOIN store s ON ss.ss_store_sk = s.s_store_sk
    INNER JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    INNER JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND regexp_like(s.s_suite_number, '^Suite [0-9]+$')
      AND s.s_city LIKE 'A%'
      AND regexp_like(p.p_promo_name, 'Clearance')
    GROUP BY
        s.s_store_sk,
        s.s_store_name,
        s.s_city,
        s.s_state,
        s.s_suite_number,
        s.s_tax_percentage,
        p.p_promo_name
)
SELECT
    s_store_sk,
    s_store_name,
    CONCAT(s_city, ', ', s_state) AS store_location,
    s_suite_number,
    CAST(regexp_extract(s_suite_number, '\\d+') AS INTEGER) AS suite_number,
    CASE WHEN s_tax_percentage > 0.05 THEN 'HighTax' ELSE 'LowTax' END AS tax_category,
    p_promo_name,
    total_net_paid,
    txn_count,
    ROW_NUMBER() OVER (PARTITION BY s_state ORDER BY total_net_paid DESC) AS state_rank
FROM sales_by_store
ORDER BY total_net_paid DESC
LIMIT 100
