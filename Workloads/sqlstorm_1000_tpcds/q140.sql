WITH sales_data AS (
    SELECT
        d.d_year,
        d.d_quarter_name,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_item_id,
        i.i_item_sk,
        SUM(cs.cs_ext_sales_price) AS catalog_sales,
        SUM(cs.cs_net_profit) AS catalog_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_net_profit) AS store_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ws.ws_net_profit) AS web_profit,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS catalog_customers,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customers,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customers,
        COUNT(DISTINCT i.i_item_sk) AS distinct_items,
        (SELECT COALESCE(SUM(cr.cr_net_loss), 0)
         FROM catalog_returns cr
         JOIN date_dim dr ON dr.d_date_sk = cr.cr_returned_date_sk
         WHERE dr.d_year = d.d_year
           AND cr.cr_item_sk = i.i_item_sk) AS catalog_return_loss,
        (SELECT COALESCE(SUM(sr.sr_net_loss), 0)
         FROM store_returns sr
         JOIN date_dim dr ON dr.d_date_sk = sr.sr_returned_date_sk
         WHERE dr.d_year = d.d_year
           AND sr.sr_item_sk = i.i_item_sk) AS store_return_loss,
        (SELECT COALESCE(SUM(wr.wr_net_loss), 0)
         FROM web_returns wr
         JOIN date_dim dr ON dr.d_date_sk = wr.wr_returned_date_sk
         WHERE dr.d_year = d.d_year
           AND wr.wr_item_sk = i.i_item_sk) AS web_return_loss
    FROM date_dim d
    JOIN catalog_sales cs ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON i.i_item_sk = cs.cs_item_sk
    JOIN store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk AND ss.ss_item_sk = i.i_item_sk
    JOIN web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk AND ws.ws_item_sk = i.i_item_sk
    WHERE d.d_year = 2001
    GROUP BY
        d.d_year,
        d.d_quarter_name,
        i.i_category,
        i.i_class,
        i.i_brand,
        i.i_item_id,
        i.i_item_sk
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY i_category ORDER BY (catalog_sales + store_sales + web_sales) DESC) AS rank_in_category
    FROM sales_data
)
SELECT
    d_year,
    d_quarter_name,
    i_category,
    i_class,
    i_brand,
    i_item_id,
    catalog_sales,
    store_sales,
    web_sales,
    (catalog_sales + store_sales + web_sales) AS total_sales,
    catalog_profit,
    store_profit,
    web_profit,
    (catalog_profit + store_profit + web_profit) AS total_profit,
    catalog_return_loss,
    store_return_loss,
    web_return_loss,
    (catalog_return_loss + store_return_loss + web_return_loss) AS total_return_loss,
    catalog_customers,
    store_customers,
    web_customers,
    (catalog_customers + store_customers + web_customers) AS total_customers,
    distinct_items,
    rank_in_category,
    ROUND((catalog_sales + store_sales + web_sales) / NULLIF(distinct_items, 0), 2) AS avg_sales_per_item,
    ROUND((catalog_profit + store_profit + web_profit) / NULLIF((catalog_sales + store_sales + web_sales), 0), 4) AS profit_margin,
    CASE WHEN rank_in_category <= 5 THEN 'Top5' ELSE 'Other' END AS rank_group
FROM ranked
WHERE rank_in_category <= 10
ORDER BY i_category, rank_in_category
