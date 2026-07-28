WITH joined_data AS (
    SELECT
        cr.cr_returned_date_sk          AS d_date_sk,
        cr.cr_returned_time_sk,
        cr.cr_return_amount,
        cr.cr_net_loss,
        cr.cr_order_number,
        cr.cr_refunded_customer_sk      AS cust_sk,
        cs.cs_quantity,
        cs.cs_sales_price,
        cs.cs_ext_ship_cost,
        cs.cs_list_price,
        cd.cd_gender,
        cd.cd_purchase_estimate,
        sm.sm_type,
        w.w_state,
        d.d_year
    FROM catalog_returns cr
    JOIN catalog_sales cs
      ON cr.cr_order_number = cs.cs_order_number
    JOIN customer c
      ON cr.cr_refunded_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk
    JOIN customer_address ca
      ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN ship_mode sm
      ON cr.cr_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN warehouse w
      ON cr.cr_warehouse_sk = w.w_warehouse_sk
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
         AND cs.cs_sold_date_sk = d.d_date_sk
         AND c.c_first_sales_date_sk = d.d_date_sk
    JOIN time_dim t
      ON cr.cr_returned_time_sk = t.t_time_sk
         AND cs.cs_sold_time_sk = t.t_time_sk
    JOIN store_returns sr
      ON sr.sr_returned_date_sk = d.d_date_sk
         AND sr.sr_customer_sk = c.c_customer_sk
)
SELECT
    d_year,
    sm_type,
    w_state,
    SUM(cr_net_loss)                         AS total_net_loss,
    COUNT(DISTINCT cr_order_number)          AS distinct_orders,
    AVG(cs_sales_price)                      AS avg_sales_price,
    MIN(cs_ext_ship_cost)                    AS min_ship_cost,
    MAX(cs_list_price)                       AS max_list_price,
    (SELECT AVG(cd2.cd_purchase_estimate)
     FROM customer_demographics cd2
     WHERE cd2.cd_gender = cd_gender)          AS avg_estimate_by_gender
FROM joined_data
WHERE
    d_year = 2001
    AND cd_gender = 'M'
    AND cd_purchase_estimate BETWEEN 2000 AND 6000
    AND sm_type = 'AIR'
    AND w_state = 'CA'
    AND cs_quantity > 5
    AND cr_return_amount > 50
    AND EXISTS (
        SELECT 1
        FROM web_returns wr
        WHERE wr.wr_returned_date_sk = d_date_sk
          AND wr.wr_refunded_customer_sk = cust_sk
          AND wr.wr_return_amt > 100
    )
GROUP BY d_year, sm_type, w_state
ORDER BY total_net_loss DESC
LIMIT 100
