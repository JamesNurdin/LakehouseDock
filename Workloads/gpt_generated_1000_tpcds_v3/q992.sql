WITH
catalog_sales_agg AS (
    SELECT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        COUNT(*) AS catalog_orders
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_rec_start_date >= DATE '2001-01-01'
      AND cp.cp_department = 'DEPARTMENT'
      AND w.w_country = 'United States'
      AND sm.sm_type = 'AIR'
      AND cp.cp_description LIKE '%sales%'
    GROUP BY cs.cs_bill_customer_sk,
             cs.cs_call_center_sk,
             cs.cs_catalog_page_sk,
             cs.cs_ship_mode_sk,
             cs.cs_warehouse_sk
),
store_sales_agg AS (
    SELECT
        ss.ss_customer_sk AS cust_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        COUNT(*) AS store_orders
    FROM tpcds.store_sales ss
    JOIN tpcds.customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN tpcds.customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN tpcds.household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN tpcds.customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN tpcds.income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE c.c_birth_country = 'United States'
      AND cd.cd_gender = 'M'
      AND ib.ib_upper_bound >= 50000
      AND ca.ca_suite_number = 'Suite 160'
      AND ca.ca_city = 'New York'
    GROUP BY ss.ss_customer_sk
),
returns_agg AS (
    SELECT
        cr.cr_returning_customer_sk AS cust_sk,
        SUM(cr.cr_net_loss) AS returns_net_loss,
        COUNT(*) AS return_cnt
    FROM tpcds.catalog_returns cr
    JOIN tpcds.call_center cc
        ON cr.cr_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.ship_mode sm
        ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN tpcds.warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_rec_end_date >= DATE '2002-01-01'
      AND cp.cp_department = 'DEPARTMENT'
      AND sm.sm_type = 'AIR'
      AND w.w_country = 'United States'
      AND cr.cr_return_quantity > 0
    GROUP BY cr.cr_returning_customer_sk
),
sales_union AS (
    SELECT cust_sk, catalog_net_profit AS net_profit, catalog_orders AS orders
    FROM catalog_sales_agg
    UNION ALL
    SELECT cust_sk, store_net_profit AS net_profit, store_orders AS orders
    FROM store_sales_agg
),
sales_agg AS (
    SELECT
        cust_sk,
        SUM(net_profit) AS total_net_profit,
        SUM(orders) AS total_orders
    FROM sales_union
    GROUP BY cust_sk
),
cs_map AS (
    SELECT DISTINCT
        cs.cs_bill_customer_sk AS cust_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk
    FROM tpcds.catalog_sales cs
)
SELECT
    c.c_customer_id,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cc.cc_name AS call_center_name,
    cp.cp_description AS catalog_page_desc,
    sm.sm_type AS ship_mode_type,
    w.w_city AS warehouse_city,
    wp.wp_type AS web_page_type,
    sa.total_net_profit,
    sa.total_orders,
    COALESCE(ra.returns_net_loss, 0) AS returns_net_loss,
    COALESCE(ra.return_cnt, 0) AS return_cnt
FROM sales_agg sa
JOIN tpcds.customer c
    ON sa.cust_sk = c.c_customer_sk
JOIN tpcds.customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
JOIN tpcds.household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
JOIN tpcds.income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN cs_map cm
    ON cm.cust_sk = sa.cust_sk
LEFT JOIN tpcds.call_center cc
    ON cm.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN tpcds.catalog_page cp
    ON cm.cs_catalog_page_sk = cp.cp_catalog_page_sk
LEFT JOIN tpcds.ship_mode sm
    ON cm.cs_ship_mode_sk = sm.sm_ship_mode_sk
LEFT JOIN tpcds.warehouse w
    ON cm.cs_warehouse_sk = w.w_warehouse_sk
LEFT JOIN tpcds.web_page wp
    ON c.c_customer_sk = wp.wp_customer_sk
LEFT JOIN returns_agg ra
    ON ra.cust_sk = sa.cust_sk
WHERE c.c_birth_year BETWEEN 1970 AND 1980
  AND cc.cc_division_name = 'Division A'
  AND w.w_city = 'Los Angeles'
  AND wp.wp_type = 'home'
  AND sm.sm_carrier = 'UPS'
  AND cp.cp_catalog_page_id LIKE 'AAAAAAA%'
ORDER BY sa.total_net_profit DESC
LIMIT 100
