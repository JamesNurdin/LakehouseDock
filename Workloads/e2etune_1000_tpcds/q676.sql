WITH sales_agg AS (
    SELECT
        c.c_customer_sk,
        cc.cc_market_manager,
        cp.cp_type,
        SUM(cs.cs_net_paid_inc_ship) AS total_sales,
        SUM(cs.cs_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    WHERE cc.cc_rec_start_date >= DATE '2000-01-01'
      AND cc.cc_company IN (1, 2, 3)
      AND cp.cp_type IS NOT NULL
    GROUP BY c.c_customer_sk, cc.cc_market_manager, cp.cp_type
),
returns_agg AS (
    SELECT
        c.c_customer_sk,
        r.r_reason_desc,
        SUM(wr.wr_net_loss) AS total_returns,
        SUM(wr.wr_return_quantity) AS total_return_qty,
        COUNT(*) AS return_cnt
    FROM web_returns wr
    JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c ON wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE r.r_reason_desc LIKE '%damage%'
       OR r.r_reason_desc LIKE '%defect%'
    GROUP BY c.c_customer_sk, r.r_reason_desc
)
SELECT
    s.cc_market_manager,
    s.cp_type,
    SUM(s.total_sales) AS agg_total_sales,
    SUM(s.total_profit) AS agg_total_profit,
    SUM(s.sales_cnt) AS agg_sales_cnt,
    SUM(COALESCE(r.total_returns, 0)) AS agg_total_returns,
    SUM(COALESCE(r.total_return_qty, 0)) AS agg_total_return_qty,
    SUM(COALESCE(r.return_cnt, 0)) AS agg_return_cnt,
    (SUM(s.total_profit) - SUM(COALESCE(r.total_returns, 0))) AS net_contribution
FROM sales_agg s
LEFT JOIN returns_agg r ON s.c_customer_sk = r.c_customer_sk
GROUP BY s.cc_market_manager, s.cp_type
HAVING SUM(s.total_sales) > 5000
ORDER BY net_contribution DESC
LIMIT 100
