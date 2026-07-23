WITH joined_data AS (
    SELECT
        d.d_year,
        s.s_state,
        sm.sm_type,
        cd.cd_gender,
        cs.cs_ext_sales_price,
        cr.cr_return_amount,
        ws.ws_net_paid,
        inv.inv_quantity_on_hand,
        cs.cs_order_number,
        cs.cs_quantity
    FROM tpcds.date_dim d
    INNER JOIN tpcds.inventory inv
        ON inv.inv_date_sk = d.d_date_sk
    INNER JOIN tpcds.store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
    INNER JOIN tpcds.store s
        ON s.s_store_sk = sr.sr_store_sk
    INNER JOIN tpcds.customer_demographics cd
        ON cd.cd_demo_sk = sr.sr_cdemo_sk
    INNER JOIN tpcds.catalog_sales cs
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    INNER JOIN tpcds.ship_mode sm
        ON sm.sm_ship_mode_sk = cs.cs_ship_mode_sk
    INNER JOIN tpcds.catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    INNER JOIN tpcds.web_sales ws
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
      AND cd.cd_gender = 'M'
      AND s.s_state = 'CA'
      AND sm.sm_type = 'AIR'
      AND inv.inv_quantity_on_hand > 0
),
agg_by_year_state AS (
    SELECT
        d_year,
        s_state,
        sm_type,
        cd_gender,
        SUM(cs_ext_sales_price) AS total_sales,
        SUM(cr_return_amount) AS total_return_amount,
        SUM(ws_net_paid) AS total_web_net_paid,
        SUM(inv_quantity_on_hand) AS total_inventory_on_hand,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        AVG(cs_quantity) AS avg_sales_quantity
    FROM joined_data
    GROUP BY d_year, s_state, sm_type, cd_gender
)
SELECT
    d_year,
    s_state,
    sm_type,
    cd_gender,
    total_sales,
    total_return_amount,
    total_web_net_paid,
    total_inventory_on_hand,
    distinct_orders,
    avg_sales_quantity,
    total_sales / NULLIF(distinct_orders, 0) AS avg_sales_per_order
FROM agg_by_year_state
WHERE total_sales > 100000
ORDER BY total_sales DESC
LIMIT 100
