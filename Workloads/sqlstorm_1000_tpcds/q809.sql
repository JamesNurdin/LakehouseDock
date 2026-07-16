WITH sales AS (
    SELECT 
        d.d_year,
        d.d_moy AS month,
        i.i_category,
        i.i_class,
        i.i_brand,
        s.channel,
        SUM(s.net_sales) AS net_sales,
        SUM(s.net_profit) AS net_profit,
        SUM(s.quantity) AS quantity
    FROM (
        SELECT ss_sold_date_sk AS sold_date_sk,
               ss_item_sk AS item_sk,
               ss_store_sk AS chan_id,
               'store' AS channel,
               ss_net_paid AS net_sales,
               ss_net_profit AS net_profit,
               ss_quantity AS quantity
        FROM store_sales
        UNION ALL
        SELECT cs_sold_date_sk,
               cs_item_sk,
               cs_call_center_sk,
               'catalog',
               cs_net_paid,
               cs_net_profit,
               cs_quantity
        FROM catalog_sales
        UNION ALL
        SELECT ws_sold_date_sk,
               ws_item_sk,
               ws_web_page_sk,
               'web',
               ws_net_paid,
               ws_net_profit,
               ws_quantity
        FROM web_sales
    ) s
    JOIN date_dim d ON d.d_date_sk = s.sold_date_sk
    JOIN item i ON i.i_item_sk = s.item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy, i.i_category, i.i_class, i.i_brand, s.channel
),
returns AS (
    SELECT 
        d.d_year,
        d.d_moy AS month,
        i.i_category,
        i.i_class,
        i.i_brand,
        r.channel,
        SUM(r.net_loss) AS net_loss,
        SUM(r.return_quantity) AS return_quantity
    FROM (
        SELECT sr_returned_date_sk AS return_date_sk,
               sr_item_sk AS item_sk,
               sr_store_sk AS chan_id,
               'store' AS channel,
               sr_net_loss AS net_loss,
               sr_return_quantity AS return_quantity
        FROM store_returns
        UNION ALL
        SELECT cr_returned_date_sk,
               cr_item_sk,
               cr_call_center_sk,
               'catalog',
               cr_net_loss,
               cr_return_quantity
        FROM catalog_returns
        UNION ALL
        SELECT wr_returned_date_sk,
               wr_item_sk,
               wr_web_page_sk,
               'web',
               wr_net_loss,
               wr_return_quantity
        FROM web_returns
    ) r
    JOIN date_dim d ON d.d_date_sk = r.return_date_sk
    JOIN item i ON i.i_item_sk = r.item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_moy, i.i_category, i.i_class, i.i_brand, r.channel
)
SELECT 
    s.d_year,
    s.month,
    s.i_category,
    s.i_class,
    s.i_brand,
    s.channel,
    s.net_sales,
    COALESCE(r.net_loss, 0) AS net_loss,
    s.net_sales - COALESCE(r.net_loss, 0) AS net_revenue,
    s.net_profit - COALESCE(r.net_loss, 0) AS adjusted_profit,
    s.quantity - COALESCE(r.return_quantity, 0) AS net_quantity,
    ROW_NUMBER() OVER (PARTITION BY s.i_category, s.channel ORDER BY s.d_year, s.month) AS month_rank,
    LAG(s.net_sales) OVER (PARTITION BY s.i_category, s.channel ORDER BY s.d_year, s.month) AS prev_month_sales,
    ROUND(
        (s.net_sales - COALESCE(r.net_loss, 0) -
         LAG(s.net_sales - COALESCE(r.net_loss, 0)) OVER (PARTITION BY s.i_category, s.channel ORDER BY s.d_year, s.month))
        / NULLIF(LAG(s.net_sales - COALESCE(r.net_loss, 0)) OVER (PARTITION BY s.i_category, s.channel ORDER BY s.d_year, s.month), 0) * 100,
        2
    ) AS mom_sales_change_pct
FROM sales s
LEFT JOIN returns r
    ON s.d_year = r.d_year
   AND s.month = r.month
   AND s.i_category = r.i_category
   AND s.i_class = r.i_class
   AND s.i_brand = r.i_brand
   AND s.channel = r.channel
ORDER BY s.d_year, s.month, s.i_category, s.channel
