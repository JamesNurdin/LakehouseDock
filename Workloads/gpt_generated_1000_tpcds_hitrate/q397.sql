WITH sales_agg AS (
    SELECT
        cs.cs_bill_hdemo_sk AS hd_demo_sk,
        SUM(cs.cs_net_profit) AS total_net_profit,
        COUNT(*) AS sales_cnt
    FROM catalog_sales cs
    WHERE cs.cs_wholesale_cost > 10
    GROUP BY cs.cs_bill_hdemo_sk
),
returns_agg AS (
    SELECT
        wr.wr_refunded_hdemo_sk AS hd_demo_sk,
        SUM(wr.wr_net_loss) AS total_net_loss,
        COUNT(*) AS returns_cnt
    FROM web_returns wr
    WHERE wr.wr_return_tax > 5
    GROUP BY wr.wr_refunded_hdemo_sk
)
SELECT
    hd.hd_demo_sk,
    hd.hd_buy_potential,
    CONCAT('Potential:', hd.hd_buy_potential) AS buy_potential_desc,
    CASE
        WHEN hd.hd_buy_potential LIKE '%HIGH%' THEN 'HIGH'
        ELSE 'LOW'
    END AS buy_category,
    COALESCE(sa.total_net_profit, 0) AS total_net_profit,
    COALESCE(ra.total_net_loss, 0) AS total_net_loss,
    COALESCE(sa.sales_cnt, 0) AS sales_cnt,
    COALESCE(ra.returns_cnt, 0) AS returns_cnt,
    (COALESCE(sa.total_net_profit, 0) - COALESCE(ra.total_net_loss, 0)) AS profit_margin,
    (
        SELECT AVG(inner_price)
        FROM (
            SELECT cs.cs_ext_sales_price AS inner_price
            FROM catalog_sales cs
            WHERE cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        ) t
    ) AS avg_sales_price
FROM household_demographics hd
LEFT JOIN sales_agg sa ON hd.hd_demo_sk = sa.hd_demo_sk
LEFT JOIN returns_agg ra ON hd.hd_demo_sk = ra.hd_demo_sk
WHERE NOT EXISTS (
        SELECT 1
        FROM web_returns wr
        JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
        WHERE wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
          AND (regexp_like(r.r_reason_desc, '^.*defect.*$')
               OR r.r_reason_desc LIKE '%damage%')
    )
  AND regexp_extract(hd.hd_buy_potential, '(\\w+)$') = 'LOW'
ORDER BY profit_margin DESC
LIMIT 100
