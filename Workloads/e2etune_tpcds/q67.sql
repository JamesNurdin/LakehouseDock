WITH
store_agg AS (
    SELECT
        d.d_year,
        d.d_moy AS month,
        i.i_category,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        COUNT(*) AS store_txn_cnt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Excellent'
      AND d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, i.i_category
),
catalog_agg AS (
    SELECT
        d.d_year,
        d.d_moy AS month,
        i.i_category,
        SUM(cs.cs_net_profit) AS catalog_net_profit,
        SUM(cs.cs_ext_sales_price) AS catalog_sales_amount,
        COUNT(*) AS catalog_txn_cnt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN catalog_page cp ON cs.cs_catalog_page_sk = cp.cp_catalog_page_sk
    WHERE cd.cd_credit_rating = 'Excellent'
      AND d.d_year = 2001
      AND cp.cp_type = 'monthly'
    GROUP BY d.d_year, d.d_moy, i.i_category
),
web_agg AS (
    SELECT
        d.d_year,
        d.d_moy AS month,
        i.i_category,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        COUNT(*) AS web_txn_cnt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE cd.cd_credit_rating = 'Excellent'
      AND d.d_year = 2001
    GROUP BY d.d_year, d.d_moy, i.i_category
)
SELECT
    COALESCE(s.d_year, c.d_year, w.d_year) AS year,
    COALESCE(s.month, c.month, w.month) AS month,
    COALESCE(s.i_category, c.i_category, w.i_category) AS category,
    COALESCE(s.store_net_profit, 0) AS store_net_profit,
    COALESCE(c.catalog_net_profit, 0) AS catalog_net_profit,
    COALESCE(w.web_net_profit, 0) AS web_net_profit,
    (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0)) AS total_net_profit,
    RANK() OVER (
        PARTITION BY COALESCE(s.d_year, c.d_year, w.d_year), COALESCE(s.month, c.month, w.month)
        ORDER BY (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0)) DESC
    ) AS profit_rank
FROM store_agg s
FULL OUTER JOIN catalog_agg c
    ON s.d_year = c.d_year AND s.month = c.month AND s.i_category = c.i_category
FULL OUTER JOIN web_agg w
    ON COALESCE(s.d_year, c.d_year) = w.d_year
   AND COALESCE(s.month, c.month) = w.month
   AND COALESCE(s.i_category, c.i_category) = w.i_category
WHERE (COALESCE(s.store_net_profit, 0) + COALESCE(c.catalog_net_profit, 0) + COALESCE(w.web_net_profit, 0)) > 0
ORDER BY year, month, profit_rank
LIMIT 100
