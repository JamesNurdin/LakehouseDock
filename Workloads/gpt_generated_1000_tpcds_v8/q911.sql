WITH sampled_sales AS (
    SELECT *
    FROM store_sales
    TABLESAMPLE BERNOULLI (10)
    WHERE ss_quantity > 0
),
sales_agg AS (
    SELECT
        ss.ss_item_sk,
        d_sales.d_year,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(*) AS sales_cnt
    FROM sampled_sales ss
    JOIN date_dim d_sales ON ss.ss_sold_date_sk = d_sales.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE i.i_brand = 'BrandX'
      AND d_sales.d_year BETWEEN 1999 AND 2001
      AND i.i_size = 'medium'
      AND i.i_manufact_id IN (117, 479)
      AND MOD(d_sales.d_month_seq, 2) = 0
    GROUP BY ss.ss_item_sk, d_sales.d_year
),
returns_agg AS (
    SELECT
        sr.sr_item_sk,
        d_ret.d_year,
        SUM(sr.sr_return_amt) AS total_return,
        SUM(sr.sr_net_loss) AS total_loss,
        COUNT(*) AS return_cnt
    FROM store_returns sr
    JOIN date_dim d_ret ON sr.sr_returned_date_sk = d_ret.d_date_sk
    JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
    WHERE i2.i_category = 'Sports'
      AND d_ret.d_year BETWEEN 1999 AND 2001
      AND sr.sr_return_quantity > 0
      AND i2.i_color = 'red'
      AND MOD(d_ret.d_month_seq, 2) = 1
    GROUP BY sr.sr_item_sk, d_ret.d_year
),
catalog_agg AS (
    SELECT
        cs.cs_item_sk,
        d_cat.d_year,
        SUM(cs.cs_ext_sales_price) AS cat_sales,
        SUM(cs.cs_net_profit) AS cat_profit
    FROM catalog_sales cs
    JOIN date_dim d_cat ON cs.cs_sold_date_sk = d_cat.d_date_sk
    JOIN item i3 ON cs.cs_item_sk = i3.i_item_sk
    WHERE i3.i_class_id = 9
      AND d_cat.d_year = 2000
      AND cs.cs_quantity > 0
      AND i3.i_formulation = 'N/A'
      AND cs.cs_net_paid_inc_ship_tax > 1000
    GROUP BY cs.cs_item_sk, d_cat.d_year
),
excl_items AS (
    SELECT cs_item_sk AS item_sk FROM catalog_agg
    EXCEPT
    SELECT sr_item_sk FROM store_returns
),
set_union AS (
    SELECT ss_item_sk AS item_sk, total_sales FROM sales_agg
    UNION
    SELECT cs_item_sk AS item_sk, cat_sales FROM catalog_agg
),
web_dim AS (
    SELECT ws.web_site_sk,
           ws.web_name,
           d_open.d_year AS open_year
    FROM web_site ws
    JOIN date_dim d_open ON ws.web_open_date_sk = d_open.d_date_sk
    WHERE d_open.d_year = 2000
      AND ws.web_state = 'CA'
),
combined AS (
    SELECT
        a.ss_item_sk AS item_sk,
        a.d_year,
        a.total_sales,
        a.total_profit,
        COALESCE(r.total_return, 0) AS total_return,
        COALESCE(r.total_loss, 0) AS total_loss,
        COALESCE(c.cat_sales, 0) AS cat_sales,
        COALESCE(c.cat_profit, 0) AS cat_profit,
        CASE
            WHEN a.total_profit > 5000 THEN 'High'
            WHEN a.total_profit BETWEEN 1000 AND 5000 THEN 'Medium'
            ELSE 'Low'
        END AS profit_level
    FROM sales_agg a
    LEFT JOIN returns_agg r ON a.ss_item_sk = r.sr_item_sk AND a.d_year = r.d_year
    LEFT JOIN catalog_agg c ON a.ss_item_sk = c.cs_item_sk AND a.d_year = c.d_year
    JOIN excl_items e ON a.ss_item_sk = e.item_sk
),
ranked AS (
    SELECT
        item_sk,
        d_year,
        total_sales,
        total_profit,
        profit_level,
        ROW_NUMBER() OVER (PARTITION BY d_year ORDER BY total_profit DESC) AS rn,
        RANK() OVER (PARTITION BY d_year ORDER BY total_sales DESC) AS sales_rank
    FROM combined
)
SELECT
    r.item_sk,
    i.i_product_name,
    r.d_year,
    r.total_sales,
    r.total_profit,
    r.profit_level,
    r.rn,
    r.sales_rank,
    wd.web_name,
    wd.open_year
FROM ranked r
JOIN item i ON r.item_sk = i.i_item_sk
CROSS JOIN (
    SELECT DISTINCT d_year FROM date_dim WHERE d_year BETWEEN 1999 AND 2001
) dy
JOIN web_dim wd ON true
WHERE r.rn <= 10
ORDER BY r.d_year, r.rn
LIMIT 100
