WITH inventory_agg AS (
    SELECT inv_date_sk,
           SUM(inv_quantity_on_hand) AS total_inventory
    FROM inventory
    GROUP BY inv_date_sk
)
SELECT
    d.d_date,
    d.d_year,
    d.d_month_seq,
    ca.ca_state,
    hd.hd_vehicle_count,
    SUM(ss.ss_net_paid) AS total_store_sales,
    SUM(sr.sr_net_loss) AS total_store_returns_loss,
    SUM(wr.wr_net_loss) AS total_web_returns_loss,
    inv_agg.total_inventory,
    MAX(cs_l.cs_total_sales) AS total_catalog_sales,
    COUNT(DISTINCT ss.ss_ticket_number) AS store_sales_transactions,
    COUNT(DISTINCT sr.sr_ticket_number) AS store_return_transactions,
    COUNT(DISTINCT wr.wr_order_number) AS web_return_transactions
FROM date_dim d
JOIN store_sales ss
    ON ss.ss_sold_date_sk = d.d_date_sk
JOIN time_dim t
    ON ss.ss_sold_time_sk = t.t_time_sk
JOIN store_returns sr
    ON sr.sr_returned_date_sk = d.d_date_sk
    AND sr.sr_ticket_number = ss.ss_ticket_number
JOIN reason r_sr
    ON sr.sr_reason_sk = r_sr.r_reason_sk
JOIN web_returns wr
    ON wr.wr_returned_date_sk = d.d_date_sk
JOIN reason r_wr
    ON wr.wr_reason_sk = r_wr.r_reason_sk
JOIN customer_address ca
    ON ca.ca_address_sk = ss.ss_addr_sk
JOIN household_demographics hd
    ON hd.hd_demo_sk = ss.ss_hdemo_sk
JOIN inventory_agg inv_agg
    ON inv_agg.inv_date_sk = d.d_date_sk
CROSS JOIN LATERAL (
    SELECT SUM(cs.cs_ext_sales_price) AS cs_total_sales
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk = d.d_date_sk
) cs_l
WHERE d.d_year = 2000
  AND ca.ca_state IN ('CA', 'TX')
  AND hd.hd_vehicle_count >= 2
  AND r_sr.r_reason_desc = 'Did not like the color'
  AND t.t_hour BETWEEN 9 AND 17
GROUP BY d.d_date, d.d_year, d.d_month_seq, ca.ca_state, hd.hd_vehicle_count, inv_agg.total_inventory, cs_l.cs_total_sales
ORDER BY total_store_sales DESC
LIMIT 100
