WITH detailed_sales AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid_inc_tax,
        cs.cs_sold_date_sk,
        ws.ws_order_number,
        ws.ws_net_paid_inc_tax,
        ws.ws_sold_date_sk,
        sm.sm_ship_mode_id,
        sm.sm_type,
        d.d_year,
        d.d_month_seq,
        cp.cp_department,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        hd_bill.hd_income_band_sk AS bill_income_band,
        hd_ship.hd_income_band_sk AS ship_income_band,
        wp.wp_type AS web_page_type,
        CASE
            WHEN cs.cs_net_paid_inc_tax > ws.ws_net_paid_inc_tax THEN 'Catalog > Web'
            WHEN cs.cs_net_paid_inc_tax < ws.ws_net_paid_inc_tax THEN 'Web > Catalog'
            ELSE 'Equal'
        END AS revenue_side
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer_address ca_bill ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN household_demographics hd_bill ON cs.cs_bill_hdemo_sk = hd_bill.hd_demo_sk
    JOIN customer_address ca_ship ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN household_demographics hd_ship ON cs.cs_ship_hdemo_sk = hd_ship.hd_demo_sk
    JOIN web_sales ws ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
        AND ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_page wp ON ws.ws_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca_ws_bill ON ws.ws_bill_addr_sk = ca_ws_bill.ca_address_sk
    JOIN household_demographics hd_ws_bill ON ws.ws_bill_hdemo_sk = hd_ws_bill.hd_demo_sk
    JOIN customer_address ca_ws_ship ON ws.ws_ship_addr_sk = ca_ws_ship.ca_address_sk
    JOIN household_demographics hd_ws_ship ON ws.ws_ship_hdemo_sk = hd_ws_ship.hd_demo_sk
    WHERE d.d_year = 2001
      AND sm.sm_type = 'AIR'
      AND cp.cp_department = 'Electronics'
)
SELECT
    sm_ship_mode_id,
    d_year,
    d_month_seq,
    cp_department,
    SUM(cs_net_paid_inc_tax) AS catalog_rev,
    SUM(ws_net_paid_inc_tax) AS web_rev,
    COUNT(DISTINCT cs_order_number) AS catalog_orders,
    COUNT(DISTINCT ws_order_number) AS web_orders,
    CASE
        WHEN SUM(cs_net_paid_inc_tax) > SUM(ws_net_paid_inc_tax) THEN 'Catalog Higher'
        WHEN SUM(cs_net_paid_inc_tax) < SUM(ws_net_paid_inc_tax) THEN 'Web Higher'
        ELSE 'Tie'
    END AS rev_winner,
    RANK() OVER (PARTITION BY d_year ORDER BY (SUM(cs_net_paid_inc_tax) + SUM(ws_net_paid_inc_tax)) DESC) AS yearly_rank,
    ROW_NUMBER() OVER (ORDER BY (SUM(cs_net_paid_inc_tax) + SUM(ws_net_paid_inc_tax)) DESC) AS overall_rank
FROM detailed_sales
GROUP BY sm_ship_mode_id, d_year, d_month_seq, cp_department
HAVING SUM(cs_net_paid_inc_tax) > 2000
   AND SUM(ws_net_paid_inc_tax) > 2000
   AND COUNT(DISTINCT cs_order_number) >= 10
ORDER BY d_year, yearly_rank
LIMIT 100
