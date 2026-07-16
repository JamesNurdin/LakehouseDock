SELECT
    st.s_store_id,
    st.s_store_name,
    st.s_city,
    st.s_state,
    d.d_year AS year,
    d.d_month_seq AS month_seq,
    COUNT(DISTINCT cs.cs_order_number) AS order_count,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cs.cs_sales_price * cs.cs_quantity) AS total_sales_amount,
    SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(COALESCE(cr.cr_return_amount, 0)) AS total_return_amount,
    SUM(COALESCE(cr.cr_net_loss, 0)) AS total_return_loss,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_on_hand,
    MIN(d.d_date) AS store_closed_date,
    MAX(ship_d.d_date) AS latest_ship_date,
    MAX(return_d.d_date) AS latest_return_date,
    (SUM(COALESCE(cr.cr_return_amount, 0)) / NULLIF(SUM(cs.cs_sales_price * cs.cs_quantity), 0)) * 100 AS return_rate_percent,
    (SUM(cs.cs_net_profit) - SUM(COALESCE(cr.cr_reversed_charge, 0))) AS net_profit_after_returns
FROM
    date_dim d
    JOIN store st ON st.s_closed_date_sk = d.d_date_sk
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN date_dim return_d ON cr.cr_returned_date_sk = return_d.d_date_sk
    JOIN inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN date_dim ship_d ON cs.cs_ship_date_sk = ship_d.d_date_sk
WHERE
    d.d_year = 2022
    AND st.s_state = 'CA'
GROUP BY
    st.s_store_id,
    st.s_store_name,
    st.s_city,
    st.s_state,
    d.d_year,
    d.d_month_seq
HAVING
    SUM(cs.cs_quantity) > 0
ORDER BY
    total_sales_amount DESC
LIMIT 100
