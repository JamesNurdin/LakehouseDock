WITH store_agg AS (
    SELECT
        d_sales.d_year AS sale_year,
        d_sales.d_month_seq AS sale_month,
        cd.cd_gender AS gender,
        sum(ss.ss_net_profit) AS store_net_profit,
        sum(COALESCE(sr.sr_net_loss, 0)) AS store_net_loss
    FROM store_sales ss
    JOIN date_dim d_sales
        ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN store_returns sr
        ON ss.ss_item_sk = sr.sr_item_sk
        AND ss.ss_ticket_number = sr.sr_ticket_number
    LEFT JOIN date_dim d_ret
        ON sr.sr_returned_date_sk = d_ret.d_date_sk
    GROUP BY d_sales.d_year, d_sales.d_month_seq, cd.cd_gender
),
catalog_agg AS (
    SELECT
        d_sales.d_year AS sale_year,
        d_sales.d_month_seq AS sale_month,
        cd.cd_gender AS gender,
        sum(cs.cs_net_profit) AS catalog_net_profit,
        sum(COALESCE(cr.cr_net_loss, 0)) AS catalog_net_loss
    FROM catalog_sales cs
    JOIN date_dim d_sales
        ON cs.cs_sold_date_sk = d_sales.d_date_sk
    JOIN customer c
        ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN catalog_returns cr
        ON cs.cs_item_sk = cr.cr_item_sk
        AND cs.cs_order_number = cr.cr_order_number
    LEFT JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    GROUP BY d_sales.d_year, d_sales.d_month_seq, cd.cd_gender
)
SELECT
    COALESCE(s.sale_year, c.sale_year) AS year,
    COALESCE(s.sale_month, c.sale_month) AS month_seq,
    COALESCE(s.gender, c.gender) AS gender,
    COALESCE(s.store_net_profit, 0) AS total_store_net_profit,
    COALESCE(s.store_net_loss, 0) AS total_store_net_loss,
    COALESCE(c.catalog_net_profit, 0) AS total_catalog_net_profit,
    COALESCE(c.catalog_net_loss, 0) AS total_catalog_net_loss,
    (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0)
     - (COALESCE(s.store_net_loss, 0) + COALESCE(c.catalog_net_loss, 0))) AS net_contribution
FROM store_agg s
FULL OUTER JOIN catalog_agg c
    ON s.sale_year = c.sale_year
    AND s.sale_month = c.sale_month
    AND s.gender = c.gender
ORDER BY year, month_seq, gender
