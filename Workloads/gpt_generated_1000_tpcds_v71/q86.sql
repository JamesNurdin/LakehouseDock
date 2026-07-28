WITH sales_filtered AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_bill_addr_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_promo_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk
    FROM tpcds.catalog_sales cs
    WHERE cs.cs_quantity >= 5
)
SELECT
    d_sales.d_year,
    s.s_store_name,
    p.p_promo_name,
    sm.sm_type,
    SUM(sf.cs_net_paid) AS total_net_paid,
    AVG(sf.cs_net_profit) AS avg_net_profit,
    COUNT(DISTINCT sf.cs_order_number) AS distinct_orders,
    (
        SELECT MAX(ib2.ib_upper_bound)
        FROM tpcds.income_band ib2
        WHERE ib2.ib_lower_bound > 50000
    ) AS max_high_income
FROM sales_filtered sf
JOIN tpcds.date_dim d_sales
    ON sf.cs_sold_date_sk = d_sales.d_date_sk
JOIN tpcds.store s
    ON s.s_closed_date_sk = d_sales.d_date_sk
JOIN tpcds.promotion p
    ON sf.cs_promo_sk = p.p_promo_sk
JOIN tpcds.ship_mode sm
    ON sf.cs_ship_mode_sk = sm.sm_ship_mode_sk
JOIN tpcds.warehouse w
    ON sf.cs_warehouse_sk = w.w_warehouse_sk
JOIN tpcds.call_center cc
    ON sf.cs_call_center_sk = cc.cc_call_center_sk
JOIN tpcds.catalog_page cp
    ON sf.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN tpcds.customer_address ca
    ON sf.cs_bill_addr_sk = ca.ca_address_sk
JOIN tpcds.customer_demographics cd
    ON sf.cs_bill_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
    ON sf.cs_bill_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
JOIN tpcds.web_returns wr
    ON wr.wr_refunded_addr_sk = ca.ca_address_sk
JOIN tpcds.date_dim d_wr
    ON wr.wr_returned_date_sk = d_wr.d_date_sk
JOIN tpcds.reason r
    ON wr.wr_reason_sk = r.r_reason_sk
JOIN tpcds.web_page wp
    ON wr.wr_web_page_sk = wp.wp_web_page_sk
JOIN tpcds.web_site ws
    ON ws.web_open_date_sk = d_wr.d_date_sk
WHERE
    s.s_state = 'CA'
    AND p.p_channel_radio = 'N'
    AND d_sales.d_year = 2001
    AND cp.cp_type = 'Catalog'
    AND p.p_cost > (
        SELECT AVG(p2.p_cost)
        FROM tpcds.promotion p2
        WHERE p2.p_channel_radio = 'N'
    )
    AND EXISTS (
        SELECT 1
        FROM tpcds.web_returns wr2
        WHERE wr2.wr_order_number = sf.cs_order_number
          AND wr2.wr_return_amt > 0
    )
GROUP BY d_sales.d_year, s.s_store_name, p.p_promo_name, sm.sm_type
HAVING SUM(sf.cs_net_paid) > 10000
ORDER BY total_net_paid DESC
LIMIT 100
