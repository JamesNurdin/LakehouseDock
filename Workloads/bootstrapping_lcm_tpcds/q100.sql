SELECT
    s.s_store_id,
    s.s_store_name,
    d_ss.d_year,
    d_ss.d_moy,
    SUM(ss.ss_net_paid) AS store_sales_net_paid,
    SUM(cs.cs_net_paid) AS catalog_sales_net_paid,
    SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit) AS total_net_profit,
    SUM(i.inv_quantity_on_hand) AS total_inventory_qty,
    AVG(i.inv_quantity_on_hand) AS avg_inventory_qty,
    (SUM(ss.ss_net_profit) + SUM(cs.cs_net_profit)) / NULLIF((SUM(ss.ss_net_paid) + SUM(cs.cs_net_paid)), 0) AS profit_margin,
    (SUM(ss.ss_ext_discount_amt) + SUM(cs.cs_ext_discount_amt)) / NULLIF((SUM(ss.ss_ext_sales_price) + SUM(cs.cs_ext_sales_price)), 0) AS discount_rate,
    (SUM(ss.ss_ext_tax) + SUM(cs.cs_ext_tax)) / NULLIF((SUM(ss.ss_ext_sales_price) + SUM(cs.cs_ext_sales_price)), 0) AS tax_rate,
    AVG(date_diff('day', d_ss.d_date, d_cs_ship.d_date)) AS avg_days_to_ship
FROM store_sales ss
JOIN store s
    ON ss.ss_store_sk = s.s_store_sk
JOIN date_dim d_ss
    ON ss.ss_sold_date_sk = d_ss.d_date_sk
JOIN catalog_sales cs
    ON cs.cs_sold_date_sk = d_ss.d_date_sk
JOIN date_dim d_cs_ship
    ON cs.cs_ship_date_sk = d_cs_ship.d_date_sk
JOIN inventory i
    ON i.inv_date_sk = d_ss.d_date_sk
LEFT JOIN date_dim d_closure
    ON s.s_closed_date_sk = d_closure.d_date_sk
WHERE d_ss.d_year >= 2020
GROUP BY
    s.s_store_id,
    s.s_store_name,
    d_ss.d_year,
    d_ss.d_moy
HAVING
    SUM(ss.ss_net_paid) > 0
ORDER BY
    total_net_profit DESC
LIMIT 100
