WITH sales_by_cc AS (
    SELECT
        cs.cs_call_center_sk,
        SUM(cs.cs_net_profit) AS total_sales_profit,
        SUM(cs.cs_ext_sales_price) AS total_sales_amount,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_net_profit > 0
      AND cs.cs_ext_sales_price > 0
    GROUP BY cs.cs_call_center_sk
),
returns_by_cc_reason AS (
    SELECT
        cc.cc_call_center_sk,
        r.r_reason_sk,
        SUM(sr.sr_net_loss) AS total_return_loss,
        SUM(sr.sr_return_amt) AS total_return_amount,
        COUNT(*) AS returns_cnt
    FROM store_returns sr
    JOIN customer c ON sr.sr_customer_sk = c.c_customer_sk
    JOIN catalog_sales cs ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE sr.sr_reversed_charge > 100
      AND c.c_birth_month IN (3,5,9)
      AND c.c_last_review_date >= 2452400
    GROUP BY cc.cc_call_center_sk, r.r_reason_sk
)
SELECT
    cc.cc_call_center_id,
    r.r_reason_desc,
    COALESCE(s.total_sales_profit, 0) - COALESCE(rt.total_return_loss, 0) AS net_contribution,
    CASE
        WHEN COALESCE(s.total_sales_profit, 0) - COALESCE(rt.total_return_loss, 0) > 10000 THEN 'HIGH'
        WHEN COALESCE(s.total_sales_profit, 0) - COALESCE(rt.total_return_loss, 0) > 1000 THEN 'MEDIUM'
        ELSE 'LOW'
    END AS profit_category,
    ROW_NUMBER() OVER (
        PARTITION BY r.r_reason_desc
        ORDER BY (COALESCE(s.total_sales_profit, 0) - COALESCE(rt.total_return_loss, 0)) DESC
    ) AS rank_per_reason
FROM call_center cc
LEFT JOIN sales_by_cc s ON s.cs_call_center_sk = cc.cc_call_center_sk
LEFT JOIN returns_by_cc_reason rt ON rt.cc_call_center_sk = cc.cc_call_center_sk
LEFT JOIN reason r ON r.r_reason_sk = rt.r_reason_sk
WHERE cc.cc_rec_start_date >= DATE '2001-01-01'
  AND cc.cc_rec_end_date <= DATE '2003-12-31'
  AND cc.cc_zip LIKE '4%'
ORDER BY profit_category DESC, net_contribution DESC
LIMIT 100
