WITH sales_agg AS (
    SELECT
        cc.cc_call_center_sk,
        cc.cc_name AS call_center_name,
        w.w_warehouse_sk,
        w.w_city AS warehouse_city,
        cd.cd_gender AS gender,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(cs.cs_quantity) AS total_quantity,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cs.cs_sold_date_sk BETWEEN 2450000 AND 2453650
      AND cs.cs_quantity > 0
    GROUP BY cc.cc_call_center_sk, cc.cc_name, w.w_warehouse_sk, w.w_city, cd.cd_gender
    HAVING SUM(cs.cs_net_profit) > 1000
),
returns_agg AS (
    SELECT
        cd.cd_gender AS gender,
        SUM(wr.wr_return_amt) AS total_return_amount,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
    WHERE wr.wr_returned_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY cd.cd_gender
)
SELECT
    s.call_center_name,
    s.warehouse_city,
    s.gender,
    s.total_net_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    (s.total_net_profit - COALESCE(r.total_return_amount, 0)) AS net_profit_after_returns,
    s.sales_cnt,
    COALESCE(r.return_cnt, 0) AS return_cnt,
    RANK() OVER (PARTITION BY s.warehouse_city ORDER BY (s.total_net_profit - COALESCE(r.total_return_amount, 0)) DESC) AS rank_in_city
FROM sales_agg s
LEFT JOIN returns_agg r ON s.gender = r.gender
ORDER BY net_profit_after_returns DESC
LIMIT 50
