WITH cc_sales AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_division,
        cc.cc_division_name,
        cc.cc_mkt_class,
        SUM(cs.cs_net_paid_inc_tax) AS total_net_paid_inc_tax,
        SUM(cs.cs_net_profit) AS total_net_profit,
        AVG(cs.cs_quantity) AS avg_quantity,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items
    FROM catalog_sales cs
    JOIN call_center cc
      ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_rec_start_date < DATE '2002-01-01'
      AND cc.cc_gmt_offset = -5.00
    GROUP BY cc.cc_call_center_sk, cc.cc_division, cc.cc_division_name, cc.cc_mkt_class
)
SELECT
    cc_sales.cc_division,
    cc_sales.cc_division_name,
    cc_sales.cc_mkt_class,
    cc_sales.total_net_paid_inc_tax,
    cc_sales.total_net_profit,
    cc_sales.avg_quantity,
    cc_sales.distinct_items,
    (cc_sales.total_net_profit / NULLIF(cc_sales.total_net_paid_inc_tax, 0)) AS profit_margin,
    RANK() OVER (PARTITION BY cc_sales.cc_division ORDER BY cc_sales.total_net_profit DESC) AS profit_rank_within_division
FROM cc_sales
WHERE cc_sales.total_net_paid_inc_tax > 1000000
ORDER BY cc_sales.total_net_profit DESC
LIMIT 100
