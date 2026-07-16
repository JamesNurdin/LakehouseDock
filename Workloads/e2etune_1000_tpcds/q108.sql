WITH sales_filtered AS (
    SELECT
        cs.cs_bill_customer_sk,
        cs.cs_item_sk,
        cs.cs_ship_mode_sk,
        cs.cs_ext_discount_amt,
        cs.cs_ext_tax,
        cs.cs_net_profit,
        cs.cs_net_paid_inc_tax
    FROM catalog_sales cs
    WHERE cs.cs_ext_discount_amt > 1000
      AND cs.cs_ext_tax > 0
      AND cs.cs_wholesale_cost BETWEEN 20 AND 80
),
aggregated AS (
    SELECT
        i.i_category,
        sm.sm_ship_mode_id,
        SUM(sf.cs_net_profit) AS total_net_profit,
        SUM(sf.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        AVG(sf.cs_ext_discount_amt) AS avg_discount,
        COUNT(DISTINCT sf.cs_bill_customer_sk) AS distinct_customers
    FROM sales_filtered sf
    JOIN item i ON sf.cs_item_sk = i.i_item_sk
    JOIN ship_mode sm ON sf.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON sf.cs_bill_customer_sk = c.c_customer_sk
    LEFT JOIN web_page wp ON c.c_customer_sk = wp.wp_customer_sk
    WHERE (wp.wp_type IS NULL OR wp.wp_type <> 'Admin')
    GROUP BY i.i_category, sm.sm_ship_mode_id
    HAVING SUM(sf.cs_net_profit) > 0
)
SELECT
    a.i_category,
    a.sm_ship_mode_id,
    a.total_net_profit,
    a.total_net_paid_inc_tax,
    a.avg_discount,
    a.distinct_customers,
    RANK() OVER (PARTITION BY a.i_category ORDER BY a.total_net_profit DESC) AS ship_mode_rank
FROM aggregated a
ORDER BY a.i_category, ship_mode_rank
LIMIT 200
