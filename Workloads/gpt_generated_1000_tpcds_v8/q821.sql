WITH cs_sample AS (
    SELECT *
    FROM catalog_sales
    TABLESAMPLE BERNOULLI (10)
),

sales_join AS (
    SELECT
        cs.cs_order_number,
        cs.cs_item_sk,
        cs.cs_sold_date_sk,
        cs.cs_quantity,
        cs.cs_net_profit,
        td.t_hour,
        c.c_customer_id,
        c.c_birth_year,
        hd.hd_vehicle_count,
        ib.ib_lower_bound,
        CASE WHEN cs.cs_net_profit > 1000 THEN 1 ELSE 0 END AS high_profit_flag,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY cs.cs_sold_date_sk DESC) AS rn_customer_sales,
        cs.cs_catalog_page_sk,
        cs.cs_ship_mode_sk,
        cs.cs_warehouse_sk,
        cs.cs_promo_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk
    FROM cs_sample cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE td.t_hour BETWEEN 8 AND 12
      AND hd.hd_vehicle_count > 0
      AND ib.ib_lower_bound >= 50000
      AND c.c_birth_year BETWEEN 1950 AND 1960
      AND cs.cs_quantity > 5
),

returns_join AS (
    SELECT
        cr.cr_order_number,
        cr.cr_item_sk,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        cr.cr_reversed_charge,
        td2.t_hour AS return_hour,
        CASE WHEN cr.cr_return_amount > 200 THEN 'Large' ELSE 'Small' END AS return_size
    FROM catalog_returns cr
    JOIN time_dim td2 ON cr.cr_returned_time_sk = td2.t_time_sk
    WHERE cr.cr_return_amount IS NOT NULL
),

store_sales_join AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_item_sk,
        ss.ss_sold_date_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        s.s_store_name,
        ROW_NUMBER() OVER (PARTITION BY s.s_store_name ORDER BY ss.ss_sold_date_sk DESC) AS rn_store_sales
    FROM store_sales ss
    JOIN customer c2 ON ss.ss_customer_sk = c2.c_customer_sk
    JOIN household_demographics hd2 ON ss.ss_hdemo_sk = hd2.hd_demo_sk
    JOIN customer_address ca2 ON ss.ss_addr_sk = ca2.ca_address_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN promotion p2 ON ss.ss_promo_sk = p2.p_promo_sk
    WHERE ss.ss_quantity > 2
),

store_returns_join AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_return_amt,
        sr.sr_return_quantity,
        sr.sr_return_ship_cost,
        CASE WHEN sr.sr_return_amt > 500 THEN 'High' ELSE 'Low' END AS return_level
    FROM store_returns sr
    WHERE sr.sr_return_amt IS NOT NULL
),

sales_without_returns AS (
    SELECT cs_order_number
    FROM sales_join
    EXCEPT
    SELECT cr_order_number
    FROM returns_join
),

first_select AS (
    SELECT DISTINCT
        sj.c_customer_id,
        sj.cs_order_number,
        sj.cs_net_profit,
        sj.high_profit_flag,
        sj.rn_customer_sales
    FROM sales_join sj
    WHERE sj.high_profit_flag = 1
),

second_select AS (
    SELECT DISTINCT
        ssj.s_store_name,
        ssj.ss_ticket_number,
        ssj.ss_net_paid,
        CASE WHEN srj.return_level = 'High' THEN 1 ELSE 0 END AS return_flag,
        ssj.rn_store_sales
    FROM store_sales_join ssj
    JOIN store_returns_join srj ON ssj.ss_ticket_number = srj.sr_ticket_number
    WHERE srj.return_level = 'High'
)

SELECT *
FROM (
    SELECT * FROM first_select
    UNION DISTINCT
    SELECT * FROM second_select
) combined
ORDER BY 1 ASC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
