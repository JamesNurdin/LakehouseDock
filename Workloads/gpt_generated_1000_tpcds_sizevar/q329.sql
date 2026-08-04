WITH sales_join AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_order_number,
        cs.cs_net_profit,
        cs.cs_ext_tax,
        cs.cs_coupon_amt,
        cs.cs_quantity,
        cs.cs_ext_sales_price,
        cp.cp_department,
        cp.cp_catalog_page_id,
        ca_bill.ca_state AS bill_state,
        ca_ship.ca_state AS ship_state,
        sm.sm_ship_mode_id,
        sm.sm_code,
        sm.sm_type,
        sm.sm_contract
    FROM tpcds.catalog_sales cs
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.customer_address ca_bill
        ON cs.cs_bill_addr_sk = ca_bill.ca_address_sk
    JOIN tpcds.customer_address ca_ship
        ON cs.cs_ship_addr_sk = ca_ship.ca_address_sk
    JOIN tpcds.ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE
        sm.sm_code IN ('AIR', 'SEA')
        AND sm.sm_type = 'OVERNIGHT'
        AND cp.cp_department = 'Electronics'
        AND cs.cs_ext_tax > 5
        AND cs.cs_coupon_amt < 5000
        AND cs.cs_quantity BETWEEN 1 AND 10
        AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
)
SELECT
    sj.cs_order_number,
    sj.cp_catalog_page_id,
    sj.cp_department,
    sj.bill_state,
    sj.ship_state,
    sj.sm_ship_mode_id,
    sj.sm_code,
    sj.sm_type,
    sj.sm_contract,
    sj.cs_net_profit,
    sj.cs_ext_sales_price,
    RANK() OVER (PARTITION BY sj.cp_department ORDER BY sj.cs_net_profit DESC) AS dept_profit_rank,
    ROW_NUMBER() OVER (ORDER BY sj.cs_ext_sales_price DESC) AS global_sales_rank,
    CASE
        WHEN sj.cs_net_profit > 1000 THEN 'HIGH'
        WHEN sj.cs_net_profit > 0 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    mode_item.mode_value
FROM sales_join sj
CROSS JOIN LATERAL (
    SELECT value AS mode_value
    FROM UNNEST(ARRAY[sj.sm_code, sj.sm_type]) AS t(value)
) mode_item
ORDER BY sj.cs_net_profit DESC, sj.cs_order_number
LIMIT 100
