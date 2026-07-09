WITH demo_sales AS (
    SELECT
        cd_gender,
        cd_education_status,
        SUM(ss_net_profit) AS total_profit,
        AVG(ss_sales_price) AS avg_price,
        COUNT(*) AS sales_cnt
    FROM store_sales
    JOIN customer_demographics
        ON store_sales.ss_cdemo_sk = customer_demographics.cd_demo_sk
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2453650
    GROUP BY cd_gender, cd_education_status
),
avg_tax AS (
    SELECT AVG(cc_tax_percentage) AS avg_tax_pct
    FROM call_center
    WHERE cc_market_manager = 'Julius Tran'
)
SELECT
    d.cd_gender,
    d.cd_education_status,
    d.total_profit,
    d.avg_price,
    d.sales_cnt,
    RANK() OVER (ORDER BY d.total_profit DESC) AS profit_rank,
    d.total_profit / (SELECT AVG(total_profit) FROM demo_sales) AS profit_vs_overall_avg,
    d.total_profit * t.avg_tax_pct AS tax_adjusted_profit
FROM demo_sales d
CROSS JOIN avg_tax t
WHERE d.total_profit > (
    SELECT AVG(ss_net_profit) * 1.2
    FROM store_sales
    WHERE ss_sold_date_sk BETWEEN 2450000 AND 2453650
)
ORDER BY profit_rank
LIMIT 100
