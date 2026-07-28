WITH filtered AS (
    SELECT
        d.d_year,
        cd1.cd_gender,
        cd1.cd_credit_rating,
        ss.ss_net_profit,
        ss.ss_quantity,
        ss.ss_item_sk,
        ws.ws_net_profit,
        ws.ws_ext_ship_cost,
        cr.cr_net_loss,
        cr.cr_return_amount,
        wr.wr_net_loss
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN customer_demographics cd1 ON ss.ss_cdemo_sk = cd1.cd_demo_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN web_returns wr ON wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_date_sk = d.d_date_sk
    JOIN catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
        AND cr.cr_refunded_cdemo_sk = cd1.cd_demo_sk
    WHERE d.d_year = 2001
      AND cd1.cd_gender = 'M'
      AND ss.ss_quantity > 2
      AND ws.ws_ext_ship_cost > 200
      AND cr.cr_return_amount > 500
      AND EXISTS (
          SELECT 1 FROM store_sales ss2
          WHERE ss2.ss_sold_date_sk = d.d_date_sk
            AND ss2.ss_quantity > 5
            AND ss2.ss_item_sk = ss.ss_item_sk
      )
),
agg AS (
    SELECT
        d_year,
        CASE WHEN cd_credit_rating = 'Excellent' THEN 'High' ELSE 'Other' END AS credit_category,
        cd_gender,
        COUNT(*) AS cnt_transactions,
        SUM(ss_net_profit) AS total_store_profit,
        AVG(ws_net_profit) AS avg_web_profit,
        MIN(cr_net_loss) AS min_catalog_loss,
        MAX(wr_net_loss) AS max_web_return_loss,
        SUM(CASE WHEN cd_gender = 'M' THEN ss_quantity ELSE 0 END) AS male_quantity
    FROM filtered
    GROUP BY d_year, cd_credit_rating, cd_gender
)
SELECT
    d_year,
    credit_category,
    cnt_transactions,
    total_store_profit,
    avg_web_profit,
    min_catalog_loss,
    max_web_return_loss,
    male_quantity,
    SUM(total_store_profit) OVER (PARTITION BY d_year) AS sum_profit_by_year,
    ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_store_profit DESC) AS profit_rank
FROM agg
ORDER BY total_store_profit DESC, profit_rank
LIMIT 100
