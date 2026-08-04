WITH sales_detail AS (
    SELECT
        cs.cs_sold_date_sk,
        cs.cs_warehouse_sk,
        cs.cs_bill_cdemo_sk,
        cs.cs_net_paid_inc_tax,
        cs.cs_quantity,
        cs.cs_wholesale_cost,
        cs.cs_ext_sales_price,
        cd.cd_education_status,
        cd.cd_marital_status,
        wh.w_warehouse_name,
        wh.w_state,
        ARRAY[ 
            CASE 
                WHEN cs.cs_quantity = 1 THEN 'single'
                WHEN cs.cs_quantity BETWEEN 2 AND 5 THEN 'small'
                WHEN cs.cs_quantity BETWEEN 6 AND 10 THEN 'medium'
                ELSE 'large' 
            END
        ] AS qty_category_arr
    FROM catalog_sales cs
    JOIN customer_demographics cd
      ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN warehouse wh
      ON cs.cs_warehouse_sk = wh.w_warehouse_sk
    WHERE cs.cs_net_paid_inc_tax > 1000               -- predicate 1
      AND cs.cs_quantity BETWEEN 1 AND 10             -- predicate 2
      AND cs.cs_wholesale_cost < 60                   -- predicate 3
      AND cd.cd_marital_status = 'M'                  -- predicate 4
      AND wh.w_state = 'CA'                           -- predicate 5
),
channel AS (
    SELECT * FROM (VALUES
        ('Online'),
        ('InStore')
    ) AS t(sales_channel)
)
SELECT
    sd.cs_sold_date_sk,
    sd.w_warehouse_name,
    sd.cd_education_status,
    uq.qty_category,
    ch.sales_channel,
    sd.cs_net_paid_inc_tax,
    SUM(sd.cs_net_paid_inc_tax) OVER (
        PARTITION BY sd.w_warehouse_name
        ORDER BY sd.cs_sold_date_sk
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cum_sales,
    RANK() OVER (
        PARTITION BY sd.w_warehouse_name
        ORDER BY sd.cs_net_paid_inc_tax DESC
    ) AS sales_rank
FROM sales_detail sd
CROSS JOIN channel ch
CROSS JOIN UNNEST(sd.qty_category_arr) AS uq(qty_category)
WHERE ch.sales_channel = CASE WHEN sd.cs_quantity <= 5 THEN 'Online' ELSE 'InStore' END
ORDER BY sd.w_warehouse_name, sales_rank
LIMIT 100
