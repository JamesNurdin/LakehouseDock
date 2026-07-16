WITH cs_agg AS (
    SELECT
        cs.cs_call_center_sk,
        COUNT(DISTINCT cs.cs_order_number) AS num_orders,
        SUM(cs.cs_net_paid_inc_ship_tax) AS total_net_paid,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_discount_amt) AS total_discount,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS distinct_customers
    FROM catalog_sales cs
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2452000
      AND cs.cs_net_paid_inc_ship_tax > 0
    GROUP BY cs.cs_call_center_sk
)
SELECT
    cc.cc_call_center_id,
    cc.cc_state,
    cc.cc_class,
    a.num_orders,
    a.total_net_paid,
    a.total_net_profit,
    a.total_discount,
    a.avg_discount,
    a.total_quantity,
    a.distinct_customers,
    ROW_NUMBER() OVER (PARTITION BY cc.cc_state ORDER BY a.total_net_profit DESC) AS profit_rank_state
FROM cs_agg a
JOIN call_center cc
    ON a.cs_call_center_sk = cc.cc_call_center_sk
WHERE cc.cc_class IN ('large', 'medium')
  AND cc.cc_state IN ('TN', 'GA')
  AND a.total_net_profit > 10000
ORDER BY a.total_net_profit DESC
LIMIT 100
