WITH filtered_sales AS (
    SELECT
        s.s_store_name,
        d_sales.d_year,
        d_sales.d_moy,
        ss.ss_ext_sales_price,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_ext_discount_amt,
        ss.ss_ticket_number
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    LEFT JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    WHERE (d_closed.d_date IS NULL OR d_closed.d_date > d_sales.d_date)
      AND d_sales.d_year = 1998
)
SELECT
    s_store_name,
    d_year,
    d_moy,
    SUM(ss_ext_sales_price) AS total_sales,
    SUM(ss_net_profit) AS total_profit,
    SUM(ss_quantity) AS total_quantity,
    AVG(ss_ext_discount_amt) AS avg_discount,
    COUNT(DISTINCT ss_ticket_number) AS distinct_tickets
FROM filtered_sales
GROUP BY s_store_name, d_year, d_moy
ORDER BY total_sales DESC
LIMIT 10
