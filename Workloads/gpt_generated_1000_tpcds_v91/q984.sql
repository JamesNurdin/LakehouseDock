WITH filtered_data AS (
    SELECT
        cs.cs_net_paid_inc_tax,
        cs.cs_ext_tax,
        cs.cs_net_profit,
        cs.cs_order_number,
        cd.cd_education_status,
        sr.sr_return_amt,
        sr.sr_ticket_number,
        s.s_store_id,
        s.s_state
    FROM catalog_sales cs
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN store_returns sr
        ON sr.sr_cdemo_sk = cd.cd_demo_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    WHERE cs.cs_net_paid_inc_tax > 1000
      AND cs.cs_ext_tax < 100
      AND cd.cd_education_status = 'Advanced Degree'
      AND sr.sr_return_quantity > 0
      AND s.s_state = 'CA'
),
aggregated AS (
    SELECT
        s_store_id,
        cd_education_status,
        MIN(s_state) AS store_state,
        SUM(cs_net_paid_inc_tax) AS total_sales_inc_tax,
        SUM(cs_net_profit) AS total_profit,
        SUM(sr_return_amt) AS total_return_amount,
        COUNT(DISTINCT cs_order_number) AS distinct_orders,
        COUNT(DISTINCT sr_ticket_number) AS distinct_returns
    FROM filtered_data
    GROUP BY ROLLUP (s_store_id, cd_education_status)
)
SELECT
    s_store_id,
    cd_education_status,
    store_state,
    total_sales_inc_tax,
    total_profit,
    total_return_amount,
    distinct_orders,
    distinct_returns,
    ROW_NUMBER() OVER (ORDER BY total_sales_inc_tax DESC) AS rn
FROM aggregated
ORDER BY rn
LIMIT 100
