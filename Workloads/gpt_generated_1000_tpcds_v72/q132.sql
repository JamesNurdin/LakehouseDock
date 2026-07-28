WITH sales_base AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_ship_date_sk,
        cs.cs_bill_customer_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cs.cs_call_center_sk,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cs.cs_ext_discount_amt,
        cs.cs_net_profit,
        d_sold.d_year,
        d_sold.d_month_seq,
        t.t_hour,
        cc.cc_state,
        cp.cp_catalog_number,
        cp.cp_type AS cp_type,
        hd.hd_dep_count,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        sm.sm_type,
        w.w_state,
        wp.wp_type AS wp_type,
        wp.wp_url
    FROM catalog_sales cs
    JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN date_dim d_wp_create ON wp.wp_creation_date_sk = d_wp_create.d_date_sk
    JOIN inventory inv ON cs.cs_ship_date_sk = inv.inv_date_sk
                     AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE d_sold.d_year = 2001
      AND cc.cc_state = 'CA'
      AND cp.cp_catalog_number IN (3, 8, 10)
      AND hd.hd_dep_count >= 2
      AND ib.ib_lower_bound >= 30000
      AND sm.sm_type = 'AIR'
      AND w.w_state = 'CA'
      AND wp.wp_type = 'HOME'
),
agg_sales AS (
    SELECT
        d_year,
        cc_state,
        cp_catalog_number,
        sm_type,
        COUNT(DISTINCT cs_bill_customer_sk) AS unique_customers,
        SUM(cs_ext_sales_price) AS total_sales,
        AVG(cs_ext_discount_amt) AS avg_discount,
        MIN(cs_net_profit) AS min_profit,
        MAX(cs_net_profit) AS max_profit
    FROM sales_base
    GROUP BY d_year, cc_state, cp_catalog_number, sm_type
    HAVING SUM(cs_ext_sales_price) > (
        SELECT AVG(cs_ext_sales_price) * 1.5 FROM sales_base
    )
)
SELECT
    d_year,
    cc_state,
    cp_catalog_number,
    sm_type,
    unique_customers,
    total_sales,
    avg_discount,
    min_profit,
    max_profit,
    SUM(total_sales) OVER (PARTITION BY cc_state ORDER BY cp_catalog_number ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_sales,
    RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
FROM agg_sales
ORDER BY total_sales DESC
LIMIT 100
