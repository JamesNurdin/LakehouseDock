WITH sales_agg AS (
    SELECT
        c.c_customer_id,
        d.d_year,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        CASE
            WHEN ib.ib_upper_bound <= 60000 THEN 'Low'
            WHEN ib.ib_upper_bound <= 120000 THEN 'Mid'
            ELSE 'High'
        END AS income_category,
        ib.ib_upper_bound
    FROM store_sales ss
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
      AND hd.hd_vehicle_count >= 2
      AND ib.ib_upper_bound <= 120000
      AND ss.ss_coupon_amt > 0
      AND cc.cc_state = 'CA'
    GROUP BY c.c_customer_id, d.d_year, ib.ib_upper_bound
)
SELECT
    c_customer_id,
    d_year,
    income_category,
    total_net_paid,
    distinct_tickets,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_paid DESC) AS revenue_rank,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY distinct_tickets DESC) AS ticket_rank
FROM sales_agg
ORDER BY d_year, revenue_rank
LIMIT 100
