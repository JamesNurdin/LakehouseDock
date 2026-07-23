WITH joined_data AS (
    SELECT
        s.s_store_name,
        s.s_state,
        s.s_tax_percentage,
        d_sales.d_date AS sale_date,
        d_sales.d_year,
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cs.cs_ext_sales_price,
        cr.cr_return_amount,
        cr.cr_return_tax,
        cr.cr_net_loss,
        cr.cr_reason_sk,
        sm.sm_type,
        w.w_warehouse_name,
        cd_refunded.cd_gender AS refunded_gender,
        hd_refunded.hd_vehicle_count AS refunded_vehicle_count,
        ca_refunded.ca_city AS refunded_city,
        cd_returning.cd_gender AS returning_gender,
        hd_returning.hd_vehicle_count AS returning_vehicle_count,
        ca_returning.ca_city AS returning_city
    FROM store s
    JOIN store_sales ss
        ON s.s_store_sk = ss.ss_store_sk
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN catalog_sales cs
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd_refunded
        ON cr.cr_refunded_cdemo_sk = cd_refunded.cd_demo_sk
    JOIN household_demographics hd_refunded
        ON cr.cr_refunded_hdemo_sk = hd_refunded.hd_demo_sk
    JOIN customer_address ca_refunded
        ON cr.cr_refunded_addr_sk = ca_refunded.ca_address_sk
    JOIN customer_demographics cd_returning
        ON cr.cr_returning_cdemo_sk = cd_returning.cd_demo_sk
    JOIN household_demographics hd_returning
        ON cr.cr_returning_hdemo_sk = hd_returning.hd_demo_sk
    JOIN customer_address ca_returning
        ON cr.cr_returning_addr_sk = ca_returning.ca_address_sk
    JOIN date_dim d_closed
        ON s.s_closed_date_sk = d_closed.d_date_sk
    JOIN customer_address ca_ss
        ON ss.ss_addr_sk = ca_ss.ca_address_sk
    JOIN customer_demographics cd_ss
        ON ss.ss_cdemo_sk = cd_ss.cd_demo_sk
    JOIN household_demographics hd_ss
        ON ss.ss_hdemo_sk = hd_ss.hd_demo_sk
    JOIN ship_mode sm_ret
        ON cr.cr_ship_mode_sk = sm_ret.sm_ship_mode_sk
    JOIN warehouse w_ret
        ON cr.cr_warehouse_sk = w_ret.w_warehouse_sk
    JOIN date_dim d_returned
        ON cr.cr_returned_date_sk = d_returned.d_date_sk
    JOIN date_dim d_ship
        ON cs.cs_ship_date_sk = d_ship.d_date_sk
),

store_year_agg AS (
    SELECT
        s_store_name,
        s_state,
        d_year,
        SUM(cs_net_paid) AS total_sales_net_paid,
        SUM(cs_net_profit) AS total_sales_net_profit,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(cr_return_tax) AS total_return_tax,
        SUM(cr_net_loss) AS total_net_loss,
        SUM(CASE WHEN sm_type = 'AIR' THEN cs_ext_sales_price ELSE 0 END) AS air_ship_sales,
        SUM(CASE WHEN cr_return_amount > 0 THEN 1 ELSE 0 END) AS return_count,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        SUM(CASE WHEN cr_return_amount > 0 THEN cs_net_profit - cr_return_amount ELSE cs_net_profit END) AS adjusted_net_profit
    FROM joined_data
    WHERE sale_date BETWEEN DATE '2022-01-01' AND DATE '2022-12-31'
      AND s_state = 'CA'
      AND s_tax_percentage > 0.00
      AND cs_net_paid > 100
      AND cr_return_amount > 0
      AND sm_type = 'AIR'
      AND EXISTS (
          SELECT 1
          FROM reason r
          WHERE r.r_reason_sk = cr_reason_sk
            AND r.r_reason_desc = 'Damaged'
      )
    GROUP BY s_store_name, s_state, d_year
)

SELECT
    d_year,
    COUNT(*) AS store_count,
    SUM(total_sales_net_paid) AS year_total_sales,
    AVG(adjusted_net_profit) AS avg_adjusted_net_profit,
    SUM(air_ship_sales) AS total_air_ship_sales
FROM store_year_agg
GROUP BY d_year
HAVING SUM(total_sales_net_paid) > 100000
ORDER BY d_year DESC
