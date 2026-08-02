WITH sales_returns AS (
    SELECT
        d_sold.d_date AS sale_date,
        d_sold.d_date_sk AS sale_date_sk,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        ws.web_company_name,
        SUM(cs.cs_net_profit) AS total_net_profit,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM
        catalog_sales cs
        JOIN date_dim d_sold ON cs.cs_sold_date_sk = d_sold.d_date_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        JOIN web_site ws ON ws.web_open_date_sk = d_sold.d_date_sk
        LEFT JOIN store_returns sr
            ON sr.sr_hdemo_sk = hd.hd_demo_sk
            AND sr.sr_returned_date_sk = d_sold.d_date_sk
    WHERE
        d_sold.d_year = 2001
        AND hd.hd_income_band_sk IN (15, 16, 19)
        AND hd.hd_buy_potential = '5001-10000'
        AND ws.web_company_id = 3
        AND cs.cs_net_profit > 0
    GROUP BY
        d_sold.d_date,
        d_sold.d_date_sk,
        hd.hd_demo_sk,
        hd.hd_buy_potential,
        ws.web_company_name
)
SELECT
    sr.sale_date,
    sr.hd_demo_sk,
    sr.hd_buy_potential,
    sr.web_company_name,
    sr.total_net_profit,
    sr.total_net_loss,
    (
        SELECT COUNT(*)
        FROM catalog_sales cs_sub
        WHERE cs_sub.cs_bill_hdemo_sk = sr.hd_demo_sk
          AND cs_sub.cs_sold_date_sk = sr.sale_date_sk
    ) AS sales_count_on_date,
    LAG(sr.total_net_profit) OVER (
        PARTITION BY sr.hd_buy_potential
        ORDER BY sr.sale_date
    ) AS prev_day_profit,
    SUM(sr.total_net_profit) OVER (
        PARTITION BY sr.hd_buy_potential
        ORDER BY sr.sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_profit,
    RANK() OVER (
        PARTITION BY sr.hd_buy_potential
        ORDER BY sr.total_net_profit DESC
    ) AS profit_rank,
    site_sales.total_site_sales
FROM
    sales_returns sr
    LEFT JOIN LATERAL (
        SELECT SUM(cs2.cs_ext_sales_price) AS total_site_sales
        FROM catalog_sales cs2
        WHERE cs2.cs_bill_hdemo_sk = sr.hd_demo_sk
          AND cs2.cs_sold_date_sk = sr.sale_date_sk
    ) AS site_sales ON TRUE
ORDER BY
    sr.total_net_profit DESC,
    sr.sale_date
LIMIT 100
