WITH sales_data AS (
    SELECT
        d.d_year,
        i.i_item_id,
        c.c_customer_id,
        cs.cs_net_paid,
        CASE WHEN cs.cs_net_profit > (
                SELECT avg(cs2.cs_net_profit)
                FROM catalog_sales cs2
                WHERE cs2.cs_sold_date_sk = cs.cs_sold_date_sk
            ) THEN 'Above Avg' ELSE 'Below Avg' END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cs.cs_net_paid DESC) AS rn
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    WHERE d.d_year = 2001
      AND i.i_category_id = 3
      AND EXISTS (
          SELECT 1
          FROM call_center cc
          WHERE cc.cc_call_center_sk = cs.cs_call_center_sk
            AND cc.cc_name IS NOT NULL
      )
),
returns_data AS (
    SELECT
        d.d_year,
        i.i_item_id,
        c.c_customer_id,
        cr.cr_refunded_cash * -1 AS cs_net_paid,
        CASE WHEN cr.cr_return_amount > 0 THEN 'Loss' ELSE 'No Loss' END AS profit_category,
        ROW_NUMBER() OVER (PARTITION BY d.d_year ORDER BY cr.cr_refunded_cash DESC) AS rn
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer c ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    WHERE d.d_year = 2001
      AND r.r_reason_desc LIKE '%price%'
)
SELECT * FROM sales_data
UNION ALL
SELECT * FROM returns_data
LIMIT 100
