WITH sales_with_page AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_net_paid_inc_ship,
        cs.cs_list_price,
        cs.cs_ship_date_sk,
        cs.cs_catalog_page_sk,
        cs.cs_bill_hdemo_sk,
        cs.cs_bill_addr_sk,
        cp.cp_department,
        cp.cp_catalog_page_id,
        hd.hd_income_band_sk,
        hd.hd_vehicle_count,
        hd.hd_demo_sk,
        ca.ca_state,
        ca.ca_address_sk,
        ib.ib_lower_bound,
        ib.ib_upper_bound
    FROM
        catalog_sales cs
        JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    WHERE
        cs.cs_list_price > 50
        AND hd.hd_vehicle_count > 0
        AND ib.ib_upper_bound < 100000
)
SELECT
    swp.cs_order_number,
    swp.cp_department,
    swp.cs_net_profit,
    swp.cs_net_paid_inc_ship,
    swp.cs_ship_date_sk,
    swp.hd_income_band_sk,
    swp.ib_lower_bound,
    swp.ib_upper_bound,
    COALESCE(sr.sr_return_amt, 0) AS return_amount,
    CASE WHEN sr.sr_return_amt IS NULL THEN 'No Return' ELSE 'Returned' END AS return_flag,
    (
        SELECT AVG(cs2.cs_net_paid_inc_ship)
        FROM catalog_sales cs2
        JOIN catalog_page cp2 ON cs2.cs_catalog_page_sk = cp2.cp_catalog_page_sk
        WHERE cp2.cp_department = swp.cp_department
    ) AS avg_department_net_paid,
    RANK() OVER (
        PARTITION BY swp.cp_department, swp.ib_lower_bound
        ORDER BY swp.cs_net_profit DESC
    ) AS profit_rank
FROM
    sales_with_page swp
    LEFT JOIN store_returns sr
        ON sr.sr_hdemo_sk = swp.hd_demo_sk
        AND sr.sr_addr_sk = swp.ca_address_sk
ORDER BY
    profit_rank,
    swp.cs_order_number
