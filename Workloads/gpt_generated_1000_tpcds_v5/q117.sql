WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        cd.cd_gender,
        hd.hd_vehicle_count,
        SUM(ss.ss_net_paid) AS total_net_paid,
        AVG(ss.ss_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT ss.ss_ticket_number) AS cnt_tickets,
        MIN(ss.ss_sales_price) AS min_sales_price,
        MAX(ss.ss_ext_wholesale_cost) AS max_wholesale_cost
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN inventory i
        ON i.inv_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND cd.cd_gender = 'M'
      AND hd.hd_vehicle_count >= 1
      AND i.inv_warehouse_sk = 12
      AND ss.ss_coupon_amt > 5000
      AND EXISTS (
          SELECT 1 FROM inventory i2
          WHERE i2.inv_item_sk = ss.ss_item_sk
            AND i2.inv_quantity_on_hand > 0
      )
    GROUP BY d.d_year, d.d_month_seq, cd.cd_gender, hd.hd_vehicle_count
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.cd_gender,
    s.hd_vehicle_count,
    s.total_net_paid,
    s.avg_discount,
    s.cnt_tickets,
    s.min_sales_price,
    s.max_wholesale_cost,
    SUM(s.total_net_paid) OVER (
        PARTITION BY s.d_year
        ORDER BY s.d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_year_net
FROM sales_agg s
WHERE s.avg_discount > 0
ORDER BY s.d_year, s.d_month_seq DESC
