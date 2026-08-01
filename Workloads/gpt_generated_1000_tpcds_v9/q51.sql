WITH base AS (
    SELECT
        cp.cp_department,
        cp.cp_catalog_number,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cd.cd_purchase_estimate,
        cd.cd_dep_college_count,
        c.c_customer_sk,
        SUM(cs.cs_ext_sales_price) AS sum_sales_price,
        SUM(cr.cr_return_amount) AS sum_return_amount,
        SUM(cr.cr_net_loss) AS sum_net_loss,
        COUNT(DISTINCT cs.cs_order_number) AS order_cnt,
        t.t_hour
    FROM catalog_sales cs
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN time_dim t ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_page wp ON wp.wp_customer_sk = c.c_customer_sk
    JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
        AND cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        cp.cp_department = 'Electronics' AND
        cp.cp_type = 'Catalog' AND
        cd.cd_purchase_estimate >= 7000 AND
        cd.cd_dep_college_count > 0 AND
        ib.ib_upper_bound <= 50000 AND
        t.t_hour BETWEEN 9 AND 18 AND
        cr.cr_reason_sk IN (5, 17, 32) AND
        cr.cr_return_amount > 0
    GROUP BY
        cp.cp_department,
        cp.cp_catalog_number,
        ib.ib_lower_bound,
        ib.ib_upper_bound,
        cd.cd_purchase_estimate,
        cd.cd_dep_college_count,
        c.c_customer_sk,
        t.t_hour
),
agg AS (
    SELECT
        cp_department,
        ib_lower_bound,
        ib_upper_bound,
        c_customer_sk,
        SUM(sum_sales_price) AS total_sales,
        SUM(sum_return_amount) AS total_returns,
        SUM(sum_net_loss) AS total_net_loss,
        SUM(order_cnt) AS total_orders
    FROM base
    GROUP BY
        cp_department,
        ib_lower_bound,
        ib_upper_bound,
        c_customer_sk
),
ranked AS (
    SELECT
        a.*, 
        RANK() OVER (PARTITION BY cp_department ORDER BY total_net_loss DESC) AS loss_rank,
        SUM(total_sales) OVER (
            PARTITION BY cp_department
            ORDER BY ib_lower_bound
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS cumulative_sales_by_income
    FROM agg a
),
filtered AS (
    SELECT *
    FROM ranked r
    WHERE NOT EXISTS (
        SELECT 1 FROM web_page wp2
        WHERE wp2.wp_customer_sk = r.c_customer_sk
          AND wp2.wp_type = 'promo'
    )
      AND r.cumulative_sales_by_income > 100000
)
SELECT
    f.cp_department,
    f.ib_lower_bound,
    f.ib_upper_bound,
    f.total_sales,
    f.total_returns,
    f.total_net_loss,
    f.total_orders,
    f.total_net_loss / NULLIF(f.total_orders, 0) AS avg_net_loss_per_order,
    f.loss_rank,
    f.cumulative_sales_by_income
FROM filtered f
ORDER BY f.cp_department, f.loss_rank
