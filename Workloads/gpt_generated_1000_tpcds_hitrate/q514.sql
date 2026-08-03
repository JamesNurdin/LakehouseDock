WITH filtered_date AS (
    SELECT *
    FROM tpcds.date_dim
    WHERE d_year BETWEEN 1998 AND 1999
      AND d_month_seq <= 12
)
SELECT
    d.d_year,
    d.d_month_seq,
    s.s_state,
    SUM(cs.cs_net_paid)               AS catalog_sales_net,
    SUM(ss.ss_net_paid)               AS store_sales_net,
    SUM(ws.ws_net_paid)               AS web_sales_net,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    CASE
        WHEN SUM(cs.cs_net_paid) > 1000000 THEN 'HIGH'
        WHEN SUM(cs.cs_net_paid) > 500000  THEN 'MEDIUM'
        ELSE 'LOW'
    END                              AS revenue_category,
    (SELECT MAX(ib2.ib_upper_bound) FROM tpcds.income_band ib2) AS max_income_upper
FROM filtered_date d
LEFT JOIN (
    SELECT *
    FROM tpcds.catalog_sales TABLESAMPLE BERNOULLI (10)
) cs ON cs.cs_sold_date_sk = d.d_date_sk
LEFT JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
LEFT JOIN tpcds.web_sales ws   ON ws.ws_sold_date_sk = d.d_date_sk
LEFT JOIN tpcds.customer_address ca ON ca.ca_address_sk = cs.cs_bill_addr_sk
LEFT JOIN tpcds.customer_demographics cd ON cd.cd_demo_sk = cs.cs_bill_cdemo_sk
LEFT JOIN tpcds.household_demographics hd ON hd.hd_demo_sk = cs.cs_bill_hdemo_sk
LEFT JOIN tpcds.income_band ib ON ib.ib_income_band_sk = hd.hd_income_band_sk
LEFT JOIN tpcds.call_center cc ON cc.cc_call_center_sk = cs.cs_call_center_sk
LEFT JOIN tpcds.ship_mode sm ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
LEFT JOIN tpcds.warehouse w ON w.w_warehouse_sk = cs.cs_warehouse_sk
LEFT JOIN tpcds.store s ON s.s_store_sk = ss.ss_store_sk
LEFT JOIN tpcds.inventory i ON i.inv_date_sk = d.d_date_sk AND i.inv_warehouse_sk = w.w_warehouse_sk
WHERE
    ca.ca_state = 'CA'
    AND s.s_state = 'CA'
    AND cs.cs_quantity > 5
    AND ws.ws_net_paid > 500
GROUP BY
    d.d_year,
    d.d_month_seq,
    s.s_state
ORDER BY
    catalog_sales_net DESC
LIMIT 100
