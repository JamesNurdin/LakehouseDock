WITH filtered_sales AS (
    SELECT
        cs.cs_call_center_sk,
        cs.cs_sold_time_sk,
        cs.cs_bill_customer_sk,
        cs.cs_net_profit,
        cs.cs_sales_price,
        td.t_shift
    FROM catalog_sales cs
    JOIN time_dim td ON cs.cs_sold_time_sk = td.t_time_sk
    WHERE td.t_shift IN ('MORNING', 'AFTERNOON', 'EVENING')
      AND cs.cs_net_profit > 0
),
aggregated AS (
    SELECT
        cc.cc_mkt_class,
        fs.t_shift,
        SUM(fs.cs_net_profit) AS total_net_profit,
        AVG(fs.cs_sales_price) AS avg_sales_price,
        COUNT(DISTINCT fs.cs_bill_customer_sk) AS distinct_customer_cnt
    FROM filtered_sales fs
    JOIN call_center cc ON fs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN web_page wp ON fs.cs_bill_customer_sk = wp.wp_customer_sk
    WHERE cc.cc_mkt_class LIKE 'Silly%'
    GROUP BY cc.cc_mkt_class, fs.t_shift
    HAVING COUNT(DISTINCT fs.cs_bill_customer_sk) >= 10
)
SELECT
    a.cc_mkt_class,
    a.t_shift,
    a.total_net_profit,
    a.avg_sales_price,
    a.distinct_customer_cnt,
    RANK() OVER (PARTITION BY a.t_shift ORDER BY a.total_net_profit DESC) AS profit_rank
FROM aggregated a
ORDER BY a.t_shift, profit_rank
