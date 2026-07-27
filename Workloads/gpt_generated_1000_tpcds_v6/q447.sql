WITH sales_agg AS (
    SELECT
        cp.cp_type,
        sm.sm_type,
        w.w_warehouse_name,
        cd.cd_gender,
        SUM(cs.cs_ext_sales_price)               AS total_sales,
        SUM(cs.cs_net_profit)                    AS total_profit,
        SUM(sr.sr_net_loss)                      AS total_return_loss,
        COUNT(DISTINCT cs.cs_order_number)       AS order_cnt
    FROM catalog_sales cs
    JOIN catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN store_returns sr
        ON sr.sr_returned_date_sk = d.d_date_sk
        AND sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_year = 2001
      AND cs.cs_quantity > 1
      AND cs.cs_wholesale_cost > 10
      AND cp.cp_type = 'monthly'
      AND sm.sm_type = 'air'
      AND w.w_state = 'CA'
    GROUP BY
        cp.cp_type,
        sm.sm_type,
        w.w_warehouse_name,
        cd.cd_gender
)
SELECT
    cp_type,
    sm_type,
    w_warehouse_name,
    cd_gender,
    total_sales,
    total_profit,
    total_return_loss,
    (total_profit - total_return_loss) AS net_total,
    order_cnt,
    ROW_NUMBER() OVER (ORDER BY (total_profit - total_return_loss) DESC) AS rank
FROM sales_agg
ORDER BY rank
LIMIT 100
