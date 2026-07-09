SELECT
    s.s_store_id,
    s.s_state,
    d_sold.d_year,
    d_sold.d_month_seq,
    COUNT(DISTINCT cs.cs_order_number) AS num_orders,
    SUM(cs.cs_quantity) AS total_quantity_sold,
    SUM(cs.cs_sales_price * cs.cs_quantity) AS total_sales_amount,
    SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(i.inv_quantity_on_hand) AS total_inventory_on_hand,
    SUM(sr.sr_return_quantity) AS total_return_quantity,
    SUM(sr.sr_return_amt) AS total_return_amount,
    SUM(cs.cs_sales_price * cs.cs_quantity) - SUM(sr.sr_return_amt) AS net_sales_after_returns,
    CASE
        WHEN SUM(cs.cs_sales_price * cs.cs_quantity) = 0 THEN 0
        ELSE (SUM(cs.cs_sales_price * cs.cs_quantity) - SUM(sr.sr_return_amt)) / SUM(cs.cs_sales_price * cs.cs_quantity)
    END AS net_sales_ratio,
    AVG(cs.cs_ext_tax) AS avg_ext_tax,
    MAX(d_ship.d_month_seq) AS max_ship_month_seq,
    MIN(d_return.d_year) AS min_return_year
FROM catalog_sales cs
JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
JOIN date_dim d_ship ON cs.cs_ship_date_sk = d_ship.d_date_sk
JOIN date_dim d_store_closed ON cs.cs_sold_date_sk = d_store_closed.d_date_sk
JOIN store s ON s.s_closed_date_sk = d_store_closed.d_date_sk
JOIN date_dim d_return ON cs.cs_sold_date_sk = d_return.d_date_sk
JOIN store_returns sr ON sr.sr_returned_date_sk = d_return.d_date_sk AND sr.sr_store_sk = s.s_store_sk
JOIN inventory i ON i.inv_date_sk = d_sold.d_date_sk
WHERE d_sold.d_year = 2020
GROUP BY s.s_store_id, s.s_state, d_sold.d_year, d_sold.d_month_seq
HAVING SUM(cs.cs_quantity) > 0
ORDER BY net_sales_after_returns DESC
LIMIT 100
