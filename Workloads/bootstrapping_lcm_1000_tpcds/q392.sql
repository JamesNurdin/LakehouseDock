WITH store_returns AS (
    SELECT
        s.s_store_id,
        s.s_store_name,
        s.s_state,
        d.d_year,
        d.d_quarter_name,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_return_tax + cr.cr_return_ship_cost - cr.cr_fee - cr.cr_store_credit) AS total_net_return,
        AVG(cr.cr_net_loss) AS avg_net_loss,
        COUNT(DISTINCT cr.cr_order_number) AS distinct_orders
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN store s ON s.s_closed_date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 2015 AND 2020
      AND s.s_state IN ('CA', 'TX', 'NY')
    GROUP BY s.s_store_id, s.s_store_name, s.s_state, d.d_year, d.d_quarter_name
)
SELECT
    s_store_id,
    s_store_name,
    s_state,
    d_year,
    d_quarter_name,
    total_return_amount,
    total_return_qty,
    total_net_return,
    avg_net_loss,
    distinct_orders,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_return_amount DESC) AS store_year_rank
FROM store_returns
ORDER BY d_year, store_year_rank
LIMIT 200
