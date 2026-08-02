WITH sales_base AS (
    SELECT
        cs.cs_order_number,
        cs.cs_sold_date_sk,
        cs.cs_sold_time_sk,
        cs.cs_item_sk,
        cs.cs_quantity,
        cs.cs_net_paid,
        cs.cs_net_profit,
        c.c_customer_sk,
        c.c_customer_id,
        c.c_first_name,
        c.c_last_name,
        hd.hd_demo_sk,
        hd.hd_income_band_sk,
        hd.hd_buy_potential,
        hd.hd_dep_count,
        sm.sm_ship_mode_sk,
        sm.sm_type,
        w.w_warehouse_sk,
        d.d_year,
        d.d_month_seq,
        t.t_hour,
        cr.cr_return_amount,
        cr.cr_return_quantity,
        d_ret.d_date AS return_date,
        t_ret.t_hour AS return_hour
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN time_dim t
        ON cs.cs_sold_time_sk = t.t_time_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm
        ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
        AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    LEFT JOIN time_dim t_ret
        ON cr.cr_returned_time_sk = t_ret.t_time_sk
    WHERE d.d_year = 1998
      AND hd.hd_dep_count > 0
      AND cs.cs_quantity > 1
      AND EXISTS (
          SELECT 1
          FROM web_returns wr
          JOIN date_dim d_wr
            ON wr.wr_returned_date_sk = d_wr.d_date_sk
          WHERE wr.wr_order_number = cs.cs_order_number
            AND wr.wr_return_amt > 0
            AND d_wr.d_year = 1998
      )
),
sales_agg AS (
    SELECT
        sb.c_customer_sk,
        sb.c_customer_id,
        sb.c_first_name,
        sb.c_last_name,
        sb.hd_buy_potential,
        sb.hd_dep_count,
        sb.cs_order_number,
        part.cust_id_part,
        SUM(sb.cs_net_paid) AS total_net_paid,
        SUM(sb.cs_net_profit) AS total_net_profit,
        SUM(COALESCE(sb.cr_return_amount, 0)) AS total_return_amount
    FROM sales_base sb
    CROSS JOIN UNNEST(split(sb.c_customer_id, '-')) AS part (cust_id_part)
    GROUP BY
        sb.c_customer_sk,
        sb.c_customer_id,
        sb.c_first_name,
        sb.c_last_name,
        sb.hd_buy_potential,
        sb.hd_dep_count,
        sb.cs_order_number,
        part.cust_id_part
    HAVING SUM(sb.cs_net_paid) > 1000
)
SELECT
    a.c_customer_id,
    a.cust_id_part,
    a.c_first_name,
    a.c_last_name,
    a.hd_buy_potential,
    CASE
        WHEN a.hd_dep_count >= 5 THEN 'Large_HH'
        WHEN a.hd_dep_count > 0 THEN 'Medium_HH'
        ELSE 'Small_HH'
    END AS household_size_category,
    a.total_net_paid,
    a.total_net_profit,
    a.total_return_amount,
    ROW_NUMBER() OVER (PARTITION BY a.c_customer_id ORDER BY a.total_net_paid DESC) AS rn_spend,
    (SELECT SUM(wr2.wr_return_amt)
     FROM web_returns wr2
     WHERE wr2.wr_returning_customer_sk = a.c_customer_sk
       AND wr2.wr_order_number = a.cs_order_number) AS total_web_return_amt
FROM sales_agg a
ORDER BY a.total_net_profit DESC
LIMIT 100
