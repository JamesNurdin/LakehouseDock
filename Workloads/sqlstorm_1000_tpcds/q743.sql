WITH all_sales AS (
    SELECT cs_item_sk AS i_item_sk,
           cs_quantity AS quantity,
           cs_net_profit AS net_profit,
           cs_sold_date_sk AS sold_date_sk,
           'catalog' AS channel
    FROM catalog_sales
    UNION ALL
    SELECT ss_item_sk,
           ss_quantity,
           ss_net_profit,
           ss_sold_date_sk,
           'store'
    FROM store_sales
    UNION ALL
    SELECT ws_item_sk,
           ws_quantity,
           ws_net_profit,
           ws_sold_date_sk,
           'web'
    FROM web_sales
),
sales_agg AS (
    SELECT i_item_sk,
           SUM(quantity) AS total_quantity,
           SUM(net_profit) AS total_net_profit,
           COUNT(DISTINCT channel) AS channel_count,
           MIN(sold_date_sk) AS first_sold_date_sk,
           MAX(sold_date_sk) AS last_sold_date_sk
    FROM all_sales
    GROUP BY i_item_sk
),
returns_agg AS (
    WITH all_returns AS (
        SELECT cr_item_sk AS i_item_sk,
               cr_return_quantity AS return_quantity,
               cr_net_loss AS net_loss,
               cr_returned_date_sk AS return_date_sk,
               'catalog' AS channel
        FROM catalog_returns
        UNION ALL
        SELECT sr_item_sk,
               sr_return_quantity,
               sr_net_loss,
               sr_returned_date_sk,
               'store'
        FROM store_returns
        UNION ALL
        SELECT wr_item_sk,
               wr_return_quantity,
               wr_net_loss,
               wr_returned_date_sk,
               'web'
        FROM web_returns
    )
    SELECT i_item_sk,
           SUM(return_quantity) AS total_return_quantity,
           SUM(net_loss) AS total_return_loss,
           COUNT(DISTINCT channel) AS return_channel_count,
           MIN(return_date_sk) AS first_return_date_sk,
           MAX(return_date_sk) AS last_return_date_sk
    FROM all_returns
    GROUP BY i_item_sk
),
item_details AS (
    SELECT i.i_item_sk,
           i.i_item_id,
           i.i_product_name,
           i.i_category,
           i.i_class,
           i.i_brand,
           COALESCE(i.i_current_price, 0) AS current_price,
           i.i_color,
           i.i_size
    FROM item i
),
combined AS (
    SELECT COALESCE(s.i_item_sk, r.i_item_sk) AS i_item_sk,
           s.total_quantity,
           s.total_net_profit,
           s.channel_count,
           s.first_sold_date_sk,
           s.last_sold_date_sk,
           r.total_return_quantity,
           r.total_return_loss,
           r.return_channel_count,
           r.first_return_date_sk,
           r.last_return_date_sk
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r ON s.i_item_sk = r.i_item_sk
),
joined AS (
    SELECT d.i_item_sk,
           d.i_item_id,
           d.i_product_name,
           d.i_category,
           d.i_class,
           d.i_brand,
           d.current_price,
           d.i_color,
           d.i_size,
           COALESCE(c.total_quantity, 0) AS total_quantity,
           COALESCE(c.total_net_profit, 0) AS total_net_profit,
           COALESCE(c.total_return_quantity, 0) AS total_return_quantity,
           COALESCE(c.total_return_loss, 0) AS total_return_loss,
           (COALESCE(c.total_net_profit, 0) - COALESCE(c.total_return_loss, 0)) AS net_profit_after_returns,
           c.channel_count,
           c.return_channel_count,
           d.current_price * COALESCE(c.total_quantity, 0) AS revenue_estimate,
           CASE
               WHEN COALESCE(c.total_quantity, 0) = 0 THEN NULL
               ELSE ROUND(COALESCE(c.total_net_profit, 0) / COALESCE(c.total_quantity, 0), 2)
           END AS profit_per_unit,
           (SELECT DATE_DIFF('day',
               (SELECT d2.d_date FROM date_dim d2 WHERE d2.d_date_sk = c.first_sold_date_sk),
               (SELECT d3.d_date FROM date_dim d3 WHERE d3.d_date_sk = c.last_return_date_sk)
           )) AS days_between_sale_and_return
    FROM item_details d
    FULL OUTER JOIN combined c ON d.i_item_sk = c.i_item_sk
),
ranked AS (
    SELECT *,
           RANK() OVER (PARTITION BY i_category ORDER BY net_profit_after_returns DESC NULLS LAST) AS profit_rank,
           ROW_NUMBER() OVER (ORDER BY (total_quantity * current_price) DESC NULLS LAST) AS overall_quantity_rank,
           CONCAT('Item ', COALESCE(i_item_id, 'UNKNOWN'), ' ', COALESCE(i_product_name, ''), ' has net profit ', CAST(ROUND(net_profit_after_returns, 2) AS VARCHAR)) AS profit_summary
    FROM joined
)
SELECT
    i_item_id,
    i_product_name,
    i_category,
    i_brand,
    total_quantity,
    total_return_quantity,
    net_profit_after_returns,
    profit_per_unit,
    profit_rank,
    overall_quantity_rank,
    profit_summary,
    CASE
        WHEN total_quantity = 0 AND total_return_quantity > 0 THEN 'RETURN_ONLY'
        WHEN total_quantity > 0 AND total_return_quantity = 0 THEN 'SALE_ONLY'
        WHEN total_quantity = 0 AND total_return_quantity = 0 THEN 'NO_ACTIVITY'
        ELSE 'BOTH'
    END AS activity_flag,
    (SELECT SUM(COALESCE(total_quantity, 0)) FILTER (WHERE profit_per_unit > 100) FROM ranked) AS high_profit_quantity_sum,
    NULLIF(total_quantity, 0) AS quantity_nonzero,
    CASE WHEN (total_quantity % 2) = 0 THEN 'EVEN_QTY' ELSE 'ODD_QTY' END AS qty_parity,
    TRY_CAST(total_quantity AS BIGINT) * TRY_CAST(current_price AS DOUBLE) AS estimated_gross_sales
FROM ranked
WHERE profit_rank <= 10 OR i_category = 'Sports'
ORDER BY i_category, profit_rank
