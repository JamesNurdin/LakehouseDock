WITH distinct_catalog_sales AS (
    SELECT DISTINCT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_addr_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_catalog_page_sk,
        cs.cs_warehouse_sk,
        cs.cs_order_number,
        cs.cs_net_paid_inc_tax,
        cs.cs_net_profit
    FROM catalog_sales cs
),
distinct_store_sales AS (
    SELECT DISTINCT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_addr_sk,
        ss.ss_hdemo_sk,
        ss.ss_ticket_number,
        ss.ss_net_paid_inc_tax,
        ss.ss_net_profit
    FROM store_sales ss
)
SELECT
    cp.cp_catalog_page_id,
    w.w_warehouse_name,
    ib.ib_income_band_sk,
    d_sales.d_day_name,
    SUM(dcs.cs_net_paid_inc_tax) AS total_catalog_net_paid_inc_tax,
    SUM(dss.ss_net_paid_inc_tax) AS total_store_net_paid_inc_tax,
    SUM(dcs.cs_net_profit) + SUM(dss.ss_net_profit) AS total_combined_net_profit,
    COUNT(DISTINCT dcs.cs_order_number) AS distinct_catalog_orders,
    COUNT(DISTINCT dss.ss_ticket_number) AS distinct_store_tickets
FROM distinct_catalog_sales dcs
JOIN catalog_page cp
    ON dcs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w
    ON dcs.cs_warehouse_sk = w.w_warehouse_sk
JOIN date_dim d_sales
    ON dcs.cs_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_sales
    ON dcs.cs_sold_time_sk = t_sales.t_time_sk
JOIN customer_address ca_bill
    ON dcs.cs_bill_addr_sk = ca_bill.ca_address_sk
JOIN household_demographics hd_bill
    ON dcs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
JOIN income_band ib
    ON hd_bill.hd_income_band_sk = ib.ib_income_band_sk
JOIN date_dim d_ship
    ON dcs.cs_ship_date_sk = d_ship.d_date_sk
JOIN web_page wp
    ON wp.wp_creation_date_sk = d_ship.d_date_sk
JOIN distinct_store_sales dss
    ON dss.ss_sold_date_sk = d_sales.d_date_sk
JOIN time_dim t_store
    ON dss.ss_sold_time_sk = t_store.t_time_sk
JOIN customer_address ca_store
    ON dss.ss_addr_sk = ca_store.ca_address_sk
JOIN household_demographics hd_store
    ON dss.ss_hdemo_sk = hd_store.hd_demo_sk
JOIN income_band ib2
    ON hd_store.hd_income_band_sk = ib2.ib_income_band_sk
WHERE d_sales.d_year = 2001
GROUP BY
    cp.cp_catalog_page_id,
    w.w_warehouse_name,
    ib.ib_income_band_sk,
    d_sales.d_day_name
ORDER BY total_combined_net_profit DESC
LIMIT 100
