WITH sales AS (
    SELECT
        i.i_category AS i_category,
        date_format(d.d_date, '%Y-%m') AS month,
        sum(ss.ss_net_paid_inc_tax) AS total_sales_amount,
        sum(ss.ss_net_profit) AS total_sales_profit
    FROM store_sales ss
    JOIN date_dim d
      ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i
      ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
    GROUP BY i.i_category, date_format(d.d_date, '%Y-%m')
),
store_ret AS (
    SELECT
        i.i_category AS i_category,
        date_format(d.d_date, '%Y-%m') AS month,
        sum(sr.sr_return_amt_inc_tax) AS total_store_return_amount,
        sum(sr.sr_net_loss) AS total_store_return_loss
    FROM store_returns sr
    JOIN date_dim d
      ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
    GROUP BY i.i_category, date_format(d.d_date, '%Y-%m')
),
catalog_ret AS (
    SELECT
        i.i_category AS i_category,
        date_format(d.d_date, '%Y-%m') AS month,
        sum(cr.cr_return_amt_inc_tax) AS total_catalog_return_amount,
        sum(cr.cr_net_loss) AS total_catalog_return_loss
    FROM catalog_returns cr
    JOIN date_dim d
      ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
      ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year = 2022
    GROUP BY i.i_category, date_format(d.d_date, '%Y-%m')
)
SELECT
    s.i_category,
    s.month,
    s.total_sales_amount,
    s.total_sales_profit,
    coalesce(sr.total_store_return_amount, 0) AS total_store_return_amount,
    coalesce(sr.total_store_return_loss, 0) AS total_store_return_loss,
    coalesce(cr.total_catalog_return_amount, 0) AS total_catalog_return_amount,
    coalesce(cr.total_catalog_return_loss, 0) AS total_catalog_return_loss,
    s.total_sales_profit
        - coalesce(sr.total_store_return_loss, 0)
        - coalesce(cr.total_catalog_return_loss, 0) AS net_profit_after_returns
FROM sales s
LEFT JOIN store_ret sr
  ON s.i_category = sr.i_category
 AND s.month = sr.month
LEFT JOIN catalog_ret cr
  ON s.i_category = cr.i_category
 AND s.month = cr.month
ORDER BY s.i_category, s.month
