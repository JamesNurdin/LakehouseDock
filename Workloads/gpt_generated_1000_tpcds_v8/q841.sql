WITH cp_filtered AS (
        SELECT cp_catalog_page_id
        FROM catalog_page
        WHERE cp_catalog_page_number = 13
        EXCEPT
        SELECT cp_catalog_page_id
        FROM catalog_page
        WHERE cp_catalog_page_id LIKE 'AAAAAAA%'
    ),
    cs_sample AS (
        SELECT *
        FROM catalog_sales
        TABLESAMPLE BERNOULLI (10)
        WHERE cs_ship_cdemo_sk IN (599432, 1822764)
          AND cs_ship_addr_sk = 4009340
    )
SELECT
    cc.cc_name,
    cp.cp_department,
    ib.ib_income_band_sk,
    SUM(cs.cs_net_paid) AS sum_cs_net_paid,
    SUM(ss.ss_net_paid) AS sum_ss_net_paid,
    COUNT(DISTINCT cs.cs_order_number) AS distinct_orders,
    AVG(sr.sr_return_amt) AS avg_return_amt,
    MIN(cs.cs_ext_sales_price) AS min_ext_sales_price,
    MAX(cs.cs_ext_sales_price) AS max_ext_sales_price,
    SUM(lo.order_discount_total) AS sum_order_discount_total
FROM cs_sample cs
JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
JOIN customer_demographics cd_ship ON cs.cs_ship_cdemo_sk = cd_ship.cd_demo_sk
JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
JOIN income_band ib ON hd_ship.hd_income_band_sk = ib.ib_income_band_sk
JOIN store_sales ss ON ss.ss_sold_time_sk = td.t_time_sk
JOIN customer_demographics cd_ss ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
JOIN household_demographics hd_ss ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
JOIN customer_address ca_ss ON ss.ss_addr_sk = ca_ss.ca_address_sk
JOIN store_returns sr ON sr.sr_ticket_number = ss.ss_ticket_number
JOIN time_dim td_sr ON sr.sr_return_time_sk = td_sr.t_time_sk
LEFT JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
JOIN LATERAL (
        SELECT SUM(cs2.cs_ext_discount_amt) AS order_discount_total
        FROM catalog_sales cs2
        WHERE cs2.cs_order_number = cs.cs_order_number
    ) lo ON TRUE
WHERE cp.cp_catalog_page_id IN (SELECT cp_catalog_page_id FROM cp_filtered)
  AND cc.cc_state = 'CA'
  AND w.w_state = 'WA'
  AND ib.ib_lower_bound >= 20000
  AND ib.ib_upper_bound <= 150000
  AND td.t_hour BETWEEN 9 AND 17
  AND ca_ship.ca_state = 'TX'
GROUP BY ROLLUP (cc.cc_name, cp.cp_department, ib.ib_income_band_sk)
LIMIT 100
