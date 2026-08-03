WITH warehouse_sales AS (
    SELECT
        cs.cs_warehouse_sk,
        SUM(cs.cs_ext_sales_price) AS total_warehouse_sales,
        AVG(cs.cs_ext_sales_price) AS avg_warehouse_sales
    FROM catalog_sales cs
    GROUP BY cs.cs_warehouse_sk
),
base AS (
    SELECT
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        cc.cc_name AS call_center_name,
        sm.sm_type AS ship_mode_type,
        w.w_warehouse_name,
        ws.ws_order_number,
        cs.cs_ext_sales_price,
        cd.cd_gender,
        ROW_NUMBER() OVER (ORDER BY cs.cs_ext_sales_price DESC) AS global_row_num,
        RANK() OVER (PARTITION BY cc.cc_state ORDER BY cs.cs_ext_sales_price DESC) AS state_rank,
        CASE
            WHEN cs.cs_ext_sales_price > (
                SELECT avg_warehouse_sales
                FROM warehouse_sales ws_a
                WHERE ws_a.cs_warehouse_sk = cs.cs_warehouse_sk
            ) THEN 'Above Avg'
            ELSE 'Below Avg'
        END AS sales_vs_avg
    FROM customer c
    JOIN store_returns sr ON sr.sr_customer_sk = c.c_customer_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_sales ws ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_state = 'CA'
      AND cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_rec_end_date <= DATE '2002-12-31'
      AND c.c_birth_day = 20
      AND cs.cs_ext_sales_price > 1000
      AND EXISTS (
            SELECT 1
            FROM store_returns sr2
            WHERE sr2.sr_return_quantity > 0
              AND sr2.sr_customer_sk = c.c_customer_sk
      )
)
SELECT
    c_customer_id,
    c_first_name,
    c_last_name,
    call_center_name,
    ship_mode_type,
    w_warehouse_name,
    ws_order_number,
    cs_ext_sales_price,
    cd_gender,
    global_row_num,
    state_rank,
    sales_vs_avg
FROM base
WHERE state_rank <= 5
ORDER BY cs_ext_sales_price DESC
LIMIT 100
