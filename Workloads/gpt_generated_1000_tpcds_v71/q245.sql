WITH store_sales_agg AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_sales_price) AS avg_sales_price,
        COUNT(*) AS txn_count,
        MIN(ss.ss_ext_discount_amt) AS min_discount,
        MAX(ss.ss_ext_wholesale_cost) AS max_wholesale_cost
    FROM
        store_sales ss
        JOIN store s
            ON ss.ss_store_sk = s.s_store_sk
    WHERE
        s.s_country = 'United States'
        AND s.s_division_id = 1
        AND s.s_number_employees BETWEEN 220 AND 300
        AND ss.ss_ext_sales_price > 1500
        AND ss.ss_sales_price BETWEEN 10 AND 200
        AND ss.ss_ext_discount_amt < 300
        AND s.s_rec_start_date BETWEEN DATE '2000-01-01' AND DATE '2005-12-31'
    GROUP BY
        s.s_store_id,
        s.s_store_name,
        s.s_city,
        s.s_state
    HAVING
        SUM(ss.ss_net_paid) > 50000
        AND COUNT(*) >= 100
)
SELECT
    s_store_id,
    s_store_name,
    s_city,
    s_state,
    total_net_paid,
    avg_sales_price,
    txn_count,
    min_discount,
    max_wholesale_cost,
    RANK() OVER (ORDER BY total_net_paid DESC) AS revenue_rank
FROM
    store_sales_agg
ORDER BY
    total_net_paid DESC
LIMIT 100
