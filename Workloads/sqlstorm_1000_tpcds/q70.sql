WITH sales AS (
    SELECT cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           cs_ext_sales_price AS sales_amount,
           cs_net_profit AS profit,
           'catalog' AS channel,
           cs_promo_sk AS promo_sk,
           cs_call_center_sk AS call_center_sk
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk,
           ss_item_sk,
           ss_ext_sales_price,
           ss_net_profit,
           'store',
           ss_promo_sk,
           NULL
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk,
           ws_item_sk,
           ws_ext_sales_price,
           ws_net_profit,
           'web',
           ws_promo_sk,
           NULL
    FROM web_sales
),
returns AS (
    SELECT cr_returned_date_sk AS date_sk,
           cr_item_sk AS item_sk,
           cr_return_amount AS return_amount,
           cr_net_loss AS return_loss,
           'catalog' AS channel
    FROM catalog_returns
    UNION ALL
    SELECT sr_returned_date_sk,
           sr_item_sk,
           sr_return_amt,
           sr_net_loss,
           'store'
    FROM store_returns
    UNION ALL
    SELECT wr_returned_date_sk,
           wr_item_sk,
           wr_return_amt,
           wr_net_loss,
           'web'
    FROM web_returns
),
sales_with_date AS (
    SELECT s.*,
           d.d_year,
           d.d_quarter_seq,
           i.i_category
    FROM sales s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
),
returns_with_date AS (
    SELECT r.*,
           d.d_year,
           d.d_quarter_seq,
           i.i_category
    FROM returns r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
),
sales_agg AS (
    SELECT d_year,
           d_quarter_seq,
           i_category,
           channel,
           SUM(sales_amount) AS total_sales_amount,
           SUM(profit) AS total_profit,
           COUNT(DISTINCT promo_sk) AS distinct_promotions
    FROM sales_with_date
    GROUP BY d_year, d_quarter_seq, i_category, channel
),
returns_agg AS (
    SELECT d_year,
           d_quarter_seq,
           i_category,
           channel,
           SUM(return_amount) AS total_return_amount,
           SUM(return_loss) AS total_return_loss
    FROM returns_with_date
    GROUP BY d_year, d_quarter_seq, i_category, channel
),
final AS (
    SELECT
        sa.d_year,
        sa.d_quarter_seq,
        sa.i_category,
        sa.channel,
        sa.total_sales_amount,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        sa.total_sales_amount - COALESCE(ra.total_return_amount, 0) AS net_sales,
        sa.total_profit,
        COALESCE(ra.total_return_loss, 0) AS total_return_loss,
        sa.total_profit - COALESCE(ra.total_return_loss, 0) AS net_profit,
        CASE WHEN sa.total_sales_amount > 0 THEN (sa.total_sales_amount - COALESCE(ra.total_return_amount, 0)) / sa.total_sales_amount ELSE 0 END AS sales_retention_ratio,
        sa.distinct_promotions,
        RANK() OVER (PARTITION BY sa.d_year, sa.d_quarter_seq ORDER BY (sa.total_profit - COALESCE(ra.total_return_loss, 0)) DESC) AS profit_rank
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.d_year = ra.d_year
       AND sa.d_quarter_seq = ra.d_quarter_seq
       AND sa.i_category = ra.i_category
       AND sa.channel = ra.channel
)
SELECT *
FROM final
ORDER BY d_year, d_quarter_seq, channel
