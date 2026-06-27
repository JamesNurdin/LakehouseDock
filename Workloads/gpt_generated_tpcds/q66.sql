WITH sales AS (
    SELECT
        s.s_store_name AS store_name,
        i.i_category AS category,
        cd.cd_gender AS gender,
        SUM(ss.ss_quantity) AS total_quantity_sold,
        SUM(ss.ss_ext_sales_price) AS total_sales_amount,
        SUM(ss.ss_net_profit) AS total_net_profit
    FROM store_sales ss
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE s.s_state = 'CA'
    GROUP BY s.s_store_name, i.i_category, cd.cd_gender
),
returns AS (
    SELECT
        s.s_store_name AS store_name,
        i.i_category AS category,
        cd.cd_gender AS gender,
        SUM(sr.sr_return_quantity) AS total_quantity_returned,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_net_loss) AS total_net_loss
    FROM store_returns sr
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE s.s_state = 'CA'
    GROUP BY s.s_store_name, i.i_category, cd.cd_gender
)
SELECT
    s.store_name,
    s.category,
    s.gender,
    s.total_quantity_sold,
    COALESCE(r.total_quantity_returned, 0) AS total_quantity_returned,
    s.total_sales_amount,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    s.total_net_profit,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    (s.total_net_profit - COALESCE(r.total_net_loss, 0)) AS net_profit_after_returns,
    CASE WHEN s.total_quantity_sold = 0 THEN 0
         ELSE CAST(COALESCE(r.total_quantity_returned, 0) AS double) / s.total_quantity_sold
    END AS return_rate
FROM sales s
LEFT JOIN returns r
    ON s.store_name = r.store_name
   AND s.category = r.category
   AND s.gender = r.gender
ORDER BY net_profit_after_returns DESC
LIMIT 100
