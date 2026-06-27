WITH sales_with_returns AS (
    SELECT
        s.s_store_name AS s_store_name,
        d.d_year AS d_year,
        d.d_moy AS d_moy,
        cd.cd_gender AS cd_gender,
        ss.ss_ext_sales_price AS ss_ext_sales_price,
        ss.ss_net_profit AS ss_net_profit,
        COALESCE(sr.sr_net_loss, 0) AS return_net_loss
    FROM store_sales ss
    JOIN store s
        ON ss.ss_store_sk = s.s_store_sk
    JOIN date_dim d
        ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_ticket_number = sr.sr_ticket_number
)
SELECT
    s_store_name,
    d_year,
    d_moy,
    cd_gender,
    SUM(ss_ext_sales_price) AS total_sales_amount,
    SUM(ss_net_profit) AS total_sales_profit,
    SUM(return_net_loss) AS total_returns_net_loss,
    SUM(ss_net_profit) - SUM(return_net_loss) AS net_profit_after_returns
FROM sales_with_returns
WHERE d_year = 2001
GROUP BY s_store_name, d_year, d_moy, cd_gender
ORDER BY total_sales_amount DESC
LIMIT 100
