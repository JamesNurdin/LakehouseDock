WITH ret_agg AS (
    SELECT 
        cr.cr_warehouse_sk,
        cr.cr_ship_mode_sk,
        SUM(cr.cr_return_amount) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM catalog_returns cr
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE r.r_reason_desc = 'Damaged'
    GROUP BY cr.cr_warehouse_sk, cr.cr_ship_mode_sk
),
inv_agg AS (
    SELECT 
        i.inv_warehouse_sk AS w_warehouse_sk,
        SUM(i.inv_quantity_on_hand) AS total_inventory_qty
    FROM inventory i
    JOIN warehouse w ON i.inv_warehouse_sk = w.w_warehouse_sk
    WHERE w.w_state = 'CA'
    GROUP BY i.inv_warehouse_sk
)
SELECT
    w.w_warehouse_name,
    sm.sm_type,
    cp.cp_department,
    COUNT(DISTINCT c.c_customer_sk) AS distinct_customers,
    SUM(cs.cs_ext_sales_price) AS total_sales,
    SUM(cs.cs_net_profit) AS total_profit,
    COALESCE(r.total_return_amount, 0) AS total_returns,
    COALESCE(r.return_cnt, 0) AS return_count,
    i.total_inventory_qty,
    AVG(cs.cs_ext_discount_amt) AS avg_discount,
    MIN(cs.cs_sold_date_sk) AS earliest_sale_date_sk,
    MAX(cs.cs_sold_date_sk) AS latest_sale_date_sk
FROM catalog_sales cs
JOIN catalog_page cp               ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
JOIN ship_mode sm                  ON cs.cs_ship_mode_sk   = sm.sm_ship_mode_sk
JOIN warehouse w                   ON cs.cs_warehouse_sk   = w.w_warehouse_sk
JOIN customer c                   ON cs.cs_bill_customer_sk = c.c_customer_sk
JOIN customer_address ca          ON cs.cs_bill_addr_sk   = ca.ca_address_sk
JOIN customer_demographics cd     ON cs.cs_bill_cdemo_sk  = cd.cd_demo_sk
JOIN household_demographics hd    ON cs.cs_bill_hdemo_sk  = hd.hd_demo_sk
JOIN time_dim td                  ON cs.cs_sold_time_sk   = td.t_time_sk
LEFT JOIN ret_agg r                ON w.w_warehouse_sk = r.cr_warehouse_sk
                                    AND sm.sm_ship_mode_sk = r.cr_ship_mode_sk
LEFT JOIN inv_agg i                ON w.w_warehouse_sk = i.w_warehouse_sk
WHERE
    td.t_hour BETWEEN 9 AND 17                     -- business hours
    AND sm.sm_type = 'AIR'                         -- air shipments only
    AND w.w_state = 'CA'                           -- California warehouses
    AND cp.cp_department = 'Electronics'          -- electronics catalog pages
    AND ca.ca_state = 'TX'                         -- customers in Texas
    AND cd.cd_gender = 'M'                         -- male customers
GROUP BY
    w.w_warehouse_name,
    sm.sm_type,
    cp.cp_department,
    i.total_inventory_qty,
    r.total_return_amount,
    r.return_cnt
ORDER BY total_sales DESC
LIMIT 100
