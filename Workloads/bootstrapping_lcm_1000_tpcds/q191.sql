SELECT
    date_dim.d_year,
    date_dim.d_month_seq,
    store.s_state,
    warehouse.w_state,
    SUM(catalog_returns.cr_return_amount) AS total_return_amount,
    SUM(catalog_returns.cr_fee) AS total_fee,
    SUM(catalog_returns.cr_net_loss) AS total_net_loss,
    AVG(catalog_returns.cr_return_quantity) AS avg_return_quantity,
    COUNT(DISTINCT catalog_returns.cr_order_number) AS distinct_orders,
    SUM(CASE WHEN hd_refunded.hd_buy_potential = 'High' THEN catalog_returns.cr_return_amount ELSE 0 END) AS high_potential_returns,
    SUM(CASE WHEN hd_returning.hd_vehicle_count > 2 THEN 1 ELSE 0 END) AS returns_with_multiple_vehicles,
    MAX(catalog_returns.cr_returned_date_sk) AS max_return_date_sk
FROM catalog_returns
JOIN date_dim
    ON catalog_returns.cr_returned_date_sk = date_dim.d_date_sk
JOIN household_demographics AS hd_refunded
    ON catalog_returns.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
JOIN household_demographics AS hd_returning
    ON catalog_returns.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
JOIN warehouse
    ON catalog_returns.cr_warehouse_sk = warehouse.w_warehouse_sk
JOIN store
    ON store.s_closed_date_sk = date_dim.d_date_sk
WHERE date_dim.d_year BETWEEN 2000 AND 2005
  AND store.s_state = 'CA'
GROUP BY
    date_dim.d_year,
    date_dim.d_month_seq,
    store.s_state,
    warehouse.w_state
HAVING SUM(catalog_returns.cr_return_amount) > 10000
ORDER BY total_return_amount DESC
LIMIT 100
