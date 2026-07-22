WITH filtered_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_cdemo_sk,
        ss.ss_hdemo_sk,
        ss.ss_net_profit,
        ss.ss_customer_sk
    FROM store_sales ss
    WHERE ss.ss_customer_sk IN (
        SELECT ss2.ss_customer_sk
        FROM store_sales ss2
        WHERE ss2.ss_net_profit > 20000
    )
),
agg_sales AS (
    SELECT
        ws.web_site_id,
        ws.web_name,
        d_sales.d_year,
        ws.web_tax_percentage,
        SUM(fs.ss_net_profit) AS total_net_profit
    FROM filtered_sales fs
    JOIN date_dim d_sales
        ON fs.ss_sold_date_sk = d_sales.d_date_sk
    JOIN customer_demographics cd
        ON fs.ss_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON fs.ss_hdemo_sk = hd.hd_demo_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN web_site ws
        ON ws.web_open_date_sk = d_sales.d_date_sk
    JOIN date_dim d_close
        ON ws.web_close_date_sk = d_close.d_date_sk
    WHERE d_sales.d_year = 2002
        AND cd.cd_gender = 'M'
        AND ws.web_tax_percentage > 0.05
        AND hd.hd_buy_potential = '5001-10000'
        AND ib.ib_lower_bound >= 50000
    GROUP BY ws.web_site_id, ws.web_name, d_sales.d_year, ws.web_tax_percentage
)
SELECT
    web_site_id,
    web_name,
    d_year,
    total_net_profit,
    RANK() OVER (PARTITION BY d_year ORDER BY total_net_profit DESC) AS profit_rank,
    CASE WHEN web_tax_percentage > 0.07 THEN 'HIGH_TAX' ELSE 'NORMAL_TAX' END AS tax_category,
    (SELECT AVG(ss3.ss_net_profit) FROM store_sales ss3) AS overall_avg_net_profit
FROM agg_sales
ORDER BY d_year ASC, profit_rank ASC
LIMIT 100
