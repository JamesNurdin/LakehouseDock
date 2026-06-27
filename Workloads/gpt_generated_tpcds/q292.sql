WITH all_sales AS (
    SELECT i.i_category AS category,
           cd.cd_gender AS gender,
           cs.cs_net_paid AS sales_net_paid,
           cs.cs_net_profit AS sales_net_profit,
           CAST(0 AS decimal(7,2)) AS returns_amount
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    SELECT i.i_category,
           cd.cd_gender,
           ss.ss_net_paid,
           ss.ss_net_profit,
           CAST(0 AS decimal(7,2))
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    SELECT i.i_category,
           cd.cd_gender,
           ws.ws_net_paid,
           ws.ws_net_profit,
           CAST(0 AS decimal(7,2))
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    SELECT i.i_category,
           cd.cd_gender,
           CAST(0 AS decimal(7,2)),
           CAST(0 AS decimal(7,2)),
           cr.cr_return_amount
    FROM catalog_returns cr
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cr.cr_refunded_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    SELECT i.i_category,
           cd.cd_gender,
           CAST(0 AS decimal(7,2)),
           CAST(0 AS decimal(7,2)),
           sr.sr_return_amt
    FROM store_returns sr
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk

    UNION ALL

    SELECT i.i_category,
           cd.cd_gender,
           CAST(0 AS decimal(7,2)),
           CAST(0 AS decimal(7,2)),
           wr.wr_return_amt
    FROM web_returns wr
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON wr.wr_refunded_cdemo_sk = cd.cd_demo_sk
)
SELECT
    category,
    gender,
    SUM(sales_net_paid) AS total_sales_net_paid,
    SUM(sales_net_profit) AS total_sales_net_profit,
    SUM(returns_amount) AS total_returns_amount,
    SUM(sales_net_paid) - SUM(returns_amount) AS net_revenue_after_returns
FROM all_sales
GROUP BY category, gender
ORDER BY category, gender
