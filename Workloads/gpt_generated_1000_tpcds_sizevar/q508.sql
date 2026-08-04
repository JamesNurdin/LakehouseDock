WITH sampled_cs AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    cs.cs_sold_date_sk,
    cs.cs_item_sk,
    cs.cs_quantity,
    cs.cs_net_paid_inc_tax,
    w.w_warehouse_id,
    w.w_city,
    td.t_hour,
    CASE
        WHEN cs.cs_net_profit > 1000 THEN 'High'
        WHEN cs.cs_net_profit > 0    THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    (
        SELECT SUM(sr2.sr_return_amt)
        FROM store_returns sr2
        WHERE sr2.sr_item_sk = cs.cs_item_sk
    ) AS total_return_amount_for_item,
    ROW_NUMBER() OVER (PARTITION BY w.w_warehouse_id ORDER BY cs.cs_net_paid_inc_tax DESC) AS sales_rank_in_warehouse
FROM sampled_cs cs
FULL OUTER JOIN warehouse w
    ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN time_dim td
    ON cs.cs_sold_time_sk = td.t_time_sk
JOIN customer_address ca
    ON cs.cs_bill_addr_sk = ca.ca_address_sk
LEFT JOIN store_returns sr
    ON sr.sr_return_time_sk = td.t_time_sk
   AND sr.sr_addr_sk = ca.ca_address_sk
WHERE
    cs.cs_wholesale_cost > 50
    AND cs.cs_ext_wholesale_cost < 4000
    AND cs.cs_net_paid_inc_tax BETWEEN 300 AND 2000
    AND w.w_warehouse_sq_ft >= 500000
    AND td.t_hour BETWEEN 9 AND 17
    AND sr.sr_refunded_cash > 0
    AND cs.cs_bill_customer_sk NOT IN (SELECT sr_customer_sk FROM store_returns)
ORDER BY cs.cs_net_paid_inc_tax DESC
LIMIT 100
