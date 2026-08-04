/*
Goal: Identify high‑value sales by year, product category and store location, while accounting for returns across catalog, store and web channels and current inventory levels. The query joins all 14 selected TPC‑DS tables using only the permitted join relationships, applies realistic filter predicates, aggregates key financial measures, orders by total net paid and limits the output.
*/
WITH cs AS (
    SELECT *
    FROM tpcds.catalog_sales
    TABLESAMPLE BERNOULLI (10)
)
SELECT
    d.d_year,
    i.i_category,
    s.s_state,
    sm.sm_type,
    COUNT(DISTINCT cs.cs_order_number)                     AS num_orders,
    SUM(cs.cs_net_paid)                                    AS total_net_paid,
    SUM(COALESCE(cr.cr_return_amount, 0))                  AS total_catalog_return_amount,
    SUM(COALESCE(sr.sr_return_amt, 0))                     AS total_store_return_amount,
    SUM(COALESCE(wr.wr_return_amt, 0))                     AS total_web_return_amount,
    AVG(inv.inv_quantity_on_hand)                          AS avg_inventory_on_hand,
    MIN(cs.cs_net_paid)                                    AS min_net_paid,
    MAX(cs.cs_net_paid)                                    AS max_net_paid
FROM cs
JOIN tpcds.date_dim d
    ON cs.cs_sold_date_sk = d.d_date_sk
JOIN tpcds.time_dim t
    ON cs.cs_sold_time_sk = t.t_time_sk
JOIN tpcds.item i
    ON cs.cs_item_sk = i.i_item_sk
JOIN tpcds.customer c
    ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd
    ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
    ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.ship_mode sm
    ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN tpcds.catalog_returns cr
    ON cr.cr_order_number = cs.cs_order_number
   AND cr.cr_item_sk = cs.cs_item_sk
LEFT JOIN tpcds.store_returns sr
    ON sr.sr_item_sk = i.i_item_sk
   AND sr.sr_returned_date_sk = d.d_date_sk
LEFT JOIN tpcds.store s
    ON sr.sr_store_sk = s.s_store_sk
LEFT JOIN tpcds.inventory inv
    ON inv.inv_item_sk = i.i_item_sk
   AND inv.inv_date_sk = d.d_date_sk
LEFT JOIN tpcds.web_returns wr
    ON wr.wr_item_sk = i.i_item_sk
   AND wr.wr_returned_date_sk = d.d_date_sk
LEFT JOIN tpcds.web_site ws
    ON ws.web_open_date_sk = d.d_date_sk
WHERE d.d_year = 2001
  AND i.i_brand = 'Brand#23'
  AND cd.cd_marital_status = 'M'
  AND hd.hd_income_band_sk = 8
  AND sm.sm_type = 'AIR'
  AND s.s_state = 'CA'
  AND inv.inv_quantity_on_hand > 0
GROUP BY
    d.d_year,
    i.i_category,
    s.s_state,
    sm.sm_type
ORDER BY total_net_paid DESC
LIMIT 100
