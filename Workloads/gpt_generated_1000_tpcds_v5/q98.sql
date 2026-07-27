WITH agg AS (
    SELECT
        cc.cc_company,
        cc.cc_state,
        cp.cp_catalog_number,
        cd.cd_gender,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales,
        AVG(cs.cs_ext_discount_amt) AS avg_discount,
        COUNT(*) AS order_count
    FROM tpcds.catalog_sales cs
    JOIN tpcds.call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN tpcds.catalog_page cp
        ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN tpcds.customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cc.cc_company IN (2, 3, 4)                                   -- predicate 1
      AND cc.cc_state = 'CA'                                            -- predicate 2
      AND cp.cp_catalog_number BETWEEN 10 AND 20                       -- predicate 3
      AND cp.cp_type = 'A'                                               -- predicate 4
      AND cd.cd_gender = 'M'                                             -- predicate 5
      AND cs.cs_ship_date_sk BETWEEN 2450800 AND 2451100                -- predicate 6
      AND cs.cs_quantity >= 2                                            -- predicate 7
      AND cs.cs_net_profit > 0                                           -- predicate 8
    GROUP BY
        cc.cc_company,
        cc.cc_state,
        cp.cp_catalog_number,
        cd.cd_gender
)
SELECT
    agg.cc_company,
    agg.cc_state,
    agg.cp_catalog_number,
    agg.cd_gender,
    agg.total_net_profit,
    agg.total_sales,
    agg.avg_discount,
    agg.order_count,
    RANK() OVER (PARTITION BY agg.cc_company ORDER BY agg.total_net_profit DESC) AS profit_rank_by_company,
    SUM(agg.total_net_profit) OVER (
        PARTITION BY agg.cc_company
        ORDER BY agg.cp_catalog_number
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit_by_company_catalog
FROM agg
ORDER BY agg.total_net_profit DESC
LIMIT 100
