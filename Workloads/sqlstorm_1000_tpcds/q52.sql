WITH
cat_sales AS (
    SELECT
        i.i_item_sk,
        d.d_year,
        d.d_moy,
        SUM(cs.cs_net_paid) AS cat_net_paid,
        SUM(cs.cs_net_profit) AS cat_net_profit,
        SUM(cs.cs_ext_discount_amt) AS cat_discount,
        COUNT(*) AS cat_orders
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, d.d_year, d.d_moy
),
cat_returns AS (
    SELECT
        i.i_item_sk,
        d.d_year,
        d.d_moy,
        SUM(cr.cr_net_loss) AS cat_net_loss,
        SUM(cr.cr_return_quantity) AS cat_return_qty
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, d.d_year, d.d_moy
),
store_sales_agg AS (
    SELECT
        i.i_item_sk,
        d.d_year,
        d.d_moy,
        SUM(ss.ss_net_paid) AS store_net_paid,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_discount_amt) AS store_discount,
        COUNT(*) AS store_orders
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, d.d_year, d.d_moy
),
store_returns_agg AS (
    SELECT
        i.i_item_sk,
        d.d_year,
        d.d_moy,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_qty
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, d.d_year, d.d_moy
),
web_sales_agg AS (
    SELECT
        i.i_item_sk,
        d.d_year,
        d.d_moy,
        SUM(ws.ws_net_paid) AS web_net_paid,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_discount_amt) AS web_discount,
        COUNT(*) AS web_orders
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, d.d_year, d.d_moy
),
web_returns_agg AS (
    SELECT
        i.i_item_sk,
        d.d_year,
        d.d_moy,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_quantity) AS web_return_qty
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_item_sk, d.d_year, d.d_moy
),
combined AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        i.i_brand,
        i.i_category,
        COALESCE(cs.d_year, ss.d_year, ws.d_year) AS sales_year,
        COALESCE(cs.d_moy, ss.d_moy, ws.d_moy) AS sales_month,
        cs.cat_net_paid,
        cs.cat_net_profit,
        cr.cat_net_loss,
        ss.store_net_paid,
        ss.store_net_profit,
        sr.store_net_loss,
        ws.web_net_paid,
        ws.web_net_profit,
        wr.web_net_loss,
        (COALESCE(cs.cat_net_profit, 0) - COALESCE(cr.cat_net_loss, 0)
         + COALESCE(ss.store_net_profit, 0) - COALESCE(sr.store_net_loss, 0)
         + COALESCE(ws.web_net_profit, 0) - COALESCE(wr.web_net_loss, 0)) AS total_net_profit,
        (COALESCE(cs.cat_discount, 0) + COALESCE(ss.store_discount, 0) + COALESCE(ws.web_discount, 0)) AS total_discount
    FROM item i
    LEFT JOIN cat_sales cs ON i.i_item_sk = cs.i_item_sk
    LEFT JOIN cat_returns cr ON i.i_item_sk = cr.i_item_sk AND cs.d_year = cr.d_year AND cs.d_moy = cr.d_moy
    LEFT JOIN store_sales_agg ss ON i.i_item_sk = ss.i_item_sk
    LEFT JOIN store_returns_agg sr ON i.i_item_sk = sr.i_item_sk AND ss.d_year = sr.d_year AND ss.d_moy = sr.d_moy
    LEFT JOIN web_sales_agg ws ON i.i_item_sk = ws.i_item_sk
    LEFT JOIN web_returns_agg wr ON i.i_item_sk = wr.i_item_sk AND ws.d_year = wr.d_year AND ws.d_moy = wr.d_moy
    WHERE COALESCE(cs.d_year, ss.d_year, ws.d_year) IS NOT NULL
)
SELECT
    sales_year,
    sales_month,
    i_item_sk,
    i_product_name,
    i_brand,
    i_category,
    total_net_profit,
    total_discount,
    ROW_NUMBER() OVER (PARTITION BY sales_year, sales_month ORDER BY total_net_profit DESC) AS rank_in_month,
    SUM(total_net_profit) OVER (PARTITION BY sales_year ORDER BY sales_month ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_year_to_month
FROM combined
WHERE total_net_profit > 0
ORDER BY sales_year, sales_month, rank_in_month
LIMIT 100
