WITH max_year_cte AS (
    SELECT MAX(d_year) AS max_year FROM date_dim
)
SELECT *
FROM (
    SELECT
        cr.cr_order_number AS order_number,
        cr.cr_return_amount AS amount,
        d.d_date AS transaction_date,
        w.w_warehouse_name AS warehouse_name,
        'return' AS source,
        LAG(cr.cr_return_amount) OVER (PARTITION BY w.w_warehouse_name ORDER BY d.d_date) AS prev_amount,
        SUM(cr.cr_return_amount) OVER (PARTITION BY w.w_warehouse_name ORDER BY d.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_amount,
        max_year_cte.max_year
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN warehouse w ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    CROSS JOIN max_year_cte
    WHERE cr.cr_return_amount > 1000
      AND d.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
      AND NOT EXISTS (
          SELECT 1 FROM store_sales ss
          WHERE ss.ss_ticket_number = cr.cr_order_number
      )
    UNION
    SELECT
        cs.cs_order_number AS order_number,
        cs.cs_net_paid_inc_ship AS amount,
        d2.d_date AS transaction_date,
        w2.w_warehouse_name AS warehouse_name,
        'sale' AS source,
        NULL AS prev_amount,
        SUM(cs.cs_net_paid_inc_ship) OVER (PARTITION BY w2.w_warehouse_name ORDER BY d2.d_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cum_amount,
        max_year_cte.max_year
    FROM catalog_sales cs
    JOIN date_dim d2 ON cs.cs_sold_date_sk = d2.d_date_sk
    JOIN warehouse w2 ON cs.cs_warehouse_sk = w2.w_warehouse_sk
    CROSS JOIN max_year_cte
    WHERE cs.cs_net_paid_inc_ship > 2000
      AND d2.d_date BETWEEN DATE '2020-01-01' AND DATE '2020-12-31'
) combined
ORDER BY transaction_date DESC, amount DESC
LIMIT 100
