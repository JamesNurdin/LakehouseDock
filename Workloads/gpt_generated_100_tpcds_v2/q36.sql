WITH call_center_sales AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales
    FROM
        tpcds.catalog_sales cs
        JOIN tpcds.call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN tpcds.catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE
        cc.cc_rec_start_date >= DATE '1999-01-01'
        AND cs.cs_sales_price > 50
    GROUP BY
        cc.cc_call_center_sk,
        cc.cc_name,
        cc.cc_state
)
SELECT
    ccs.cc_name,
    ccs.cc_state,
    ccs.total_net_profit,
    ccs.total_sales,
    avg_all.avg_total_net_profit
FROM
    call_center_sales ccs
    CROSS JOIN (
        SELECT AVG(total_net_profit) AS avg_total_net_profit
        FROM call_center_sales
    ) avg_all
WHERE
    ccs.total_net_profit > avg_all.avg_total_net_profit
ORDER BY
    ccs.total_net_profit DESC
LIMIT 10
