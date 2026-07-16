SELECT
    s.s_store_id,
    s.s_store_name,
    d.d_year,
    d.d_month_seq,
    SUM(cs.cs_net_paid_inc_ship_tax) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    SUM(sr.sr_net_loss) AS total_return_loss,
    SUM(inv.inv_quantity_on_hand) AS total_inventory,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    COUNT(*) AS transaction_count,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    SUM(cs.cs_ext_discount_amt) / NULLIF(SUM(cs.cs_sales_price), 0) AS discount_rate
FROM catalog_sales cs
JOIN date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN inventory inv
    ON inv.inv_date_sk = d.d_date_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
JOIN store s
    ON s.s_store_sk = sr.sr_store_sk
    AND s.s_closed_date_sk = d.d_date_sk
WHERE d.d_year BETWEEN 1999 AND 2002
  AND s.s_state = 'CA'
GROUP BY s.s_store_id, s.s_store_name, d.d_year, d.d_month_seq
HAVING SUM(cs.cs_net_paid_inc_ship_tax) > 50000
ORDER BY total_sales DESC
LIMIT 100
