WITH
store_sales_agg AS (
    SELECT
        ss.ss_item_sk AS item_sk,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_net_paid_inc_tax) AS store_net_sales,
        COUNT(DISTINCT ss.ss_customer_sk) AS store_customers
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY ss.ss_item_sk
),
catalog_sales_agg AS (
    SELECT
        cs.cs_item_sk AS item_sk,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_net_paid_inc_tax) AS catalog_net_sales,
        COUNT(DISTINCT cs.cs_bill_customer_sk) AS catalog_customers
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cs.cs_item_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_item_sk AS item_sk,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_net_paid_inc_tax) AS web_net_sales,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS web_customers
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY ws.ws_item_sk
),
store_returns_agg AS (
    SELECT
        sr.sr_item_sk AS item_sk,
        SUM(sr.sr_net_loss) AS store_returns_loss,
        COUNT(*) AS store_returns_cnt
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY sr.sr_item_sk
),
catalog_returns_agg AS (
    SELECT
        cr.cr_item_sk AS item_sk,
        SUM(cr.cr_net_loss) AS catalog_returns_loss,
        COUNT(*) AS catalog_returns_cnt
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY cr.cr_item_sk
),
web_returns_agg AS (
    SELECT
        wr.wr_item_sk AS item_sk,
        SUM(wr.wr_net_loss) AS web_returns_loss,
        COUNT(*) AS web_returns_cnt
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    WHERE d.d_year = 2002
    GROUP BY wr.wr_item_sk
)
SELECT
    i.i_item_id,
    i.i_product_name,
    i.i_category,
    i.i_brand,
    (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)
     - COALESCE(sr.store_returns_loss, 0) - COALESCE(cr.catalog_returns_loss, 0) - COALESCE(wr.web_returns_loss, 0)) AS total_net_profit,
    (COALESCE(ss.store_net_sales, 0) + COALESCE(cs.catalog_net_sales, 0) + COALESCE(ws.web_net_sales, 0)) AS total_net_sales,
    (COALESCE(ss.store_customers, 0) + COALESCE(cs.catalog_customers, 0) + COALESCE(ws.web_customers, 0)) AS total_customers,
    CASE WHEN (COALESCE(ss.store_net_sales, 0) + COALESCE(cs.catalog_net_sales, 0) + COALESCE(ws.web_net_sales, 0)) = 0 THEN NULL
         ELSE (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)
               - COALESCE(sr.store_returns_loss, 0) - COALESCE(cr.catalog_returns_loss, 0) - COALESCE(wr.web_returns_loss, 0))
              / (COALESCE(ss.store_net_sales, 0) + COALESCE(cs.catalog_net_sales, 0) + COALESCE(ws.web_net_sales, 0))
    END AS profit_margin,
    RANK() OVER (ORDER BY (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)
                         - COALESCE(sr.store_returns_loss, 0) - COALESCE(cr.catalog_returns_loss, 0) - COALESCE(wr.web_returns_loss, 0)) DESC) AS profit_rank,
    (COALESCE(sr.store_returns_cnt, 0) + COALESCE(cr.catalog_returns_cnt, 0) + COALESCE(wr.web_returns_cnt, 0)) AS total_returns_cnt
FROM item i
LEFT JOIN store_sales_agg ss ON i.i_item_sk = ss.item_sk
LEFT JOIN catalog_sales_agg cs ON i.i_item_sk = cs.item_sk
LEFT JOIN web_sales_agg ws ON i.i_item_sk = ws.item_sk
LEFT JOIN store_returns_agg sr ON i.i_item_sk = sr.item_sk
LEFT JOIN catalog_returns_agg cr ON i.i_item_sk = cr.item_sk
LEFT JOIN web_returns_agg wr ON i.i_item_sk = wr.item_sk
WHERE (COALESCE(ss.store_net_profit, 0) + COALESCE(cs.catalog_net_profit, 0) + COALESCE(ws.web_net_profit, 0)
       - COALESCE(sr.store_returns_loss, 0) - COALESCE(cr.catalog_returns_loss, 0) - COALESCE(wr.web_returns_loss, 0)) > 0
ORDER BY total_net_profit DESC
LIMIT 10
