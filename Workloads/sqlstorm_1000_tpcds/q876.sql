WITH
sales_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        SUM(cs.cs_ext_sales_price) AS cat_sales,
        SUM(cs.cs_net_profit) AS cat_net_profit,
        SUM(cs.cs_quantity) AS cat_quantity
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    LEFT JOIN promotion p ON cs.cs_promo_sk = p.p_promo_sk
    WHERE d.d_year BETWEEN 1998 AND 2000
    GROUP BY d.d_year, i.i_category, i.i_brand, p.p_promo_name
),
returns_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        SUM(cr.cr_return_amount) AS cat_return_amount,
        SUM(cr.cr_net_loss) AS cat_net_loss,
        SUM(cr.cr_return_quantity) AS cat_return_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_brand
),
store_sales_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        SUM(ss.ss_ext_sales_price) AS store_sales,
        SUM(ss.ss_net_profit) AS store_net_profit,
        SUM(ss.ss_quantity) AS store_quantity
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_brand
),
store_returns_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        SUM(sr.sr_return_amt) AS store_return_amount,
        SUM(sr.sr_net_loss) AS store_net_loss,
        SUM(sr.sr_return_quantity) AS store_return_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_brand
),
web_sales_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        SUM(ws.ws_ext_sales_price) AS web_sales,
        SUM(ws.ws_net_profit) AS web_net_profit,
        SUM(ws.ws_quantity) AS web_quantity
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_brand
),
web_returns_agg AS (
    SELECT
        d.d_year,
        i.i_category,
        i.i_brand,
        SUM(wr.wr_return_amt) AS web_return_amount,
        SUM(wr.wr_net_loss) AS web_net_loss,
        SUM(wr.wr_return_quantity) AS web_return_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY d.d_year, i.i_category, i.i_brand
)
SELECT
    t.*,
    rank() OVER (PARTITION BY t.d_year ORDER BY t.total_sales DESC) AS sales_rank
FROM (
    SELECT
        s.d_year,
        s.i_category,
        s.i_brand,
        s.p_promo_name,
        s.cat_sales,
        s.cat_net_profit,
        r.cat_return_amount,
        r.cat_net_loss,
        ss.store_sales,
        ss.store_net_profit,
        sr.store_return_amount,
        sr.store_net_loss,
        ws.web_sales,
        ws.web_net_profit,
        wr.web_return_amount,
        wr.web_net_loss,
        (s.cat_sales + COALESCE(ss.store_sales, 0) + COALESCE(ws.web_sales, 0)) AS total_sales,
        (s.cat_net_profit + COALESCE(ss.store_net_profit, 0) + COALESCE(ws.web_net_profit, 0)) AS total_net_profit,
        (COALESCE(r.cat_return_amount, 0) + COALESCE(sr.store_return_amount, 0) + COALESCE(wr.web_return_amount, 0)) AS total_returns,
        (COALESCE(r.cat_net_loss, 0) + COALESCE(sr.store_net_loss, 0) + COALESCE(wr.web_net_loss, 0)) AS total_return_losses,
        CASE
            WHEN (s.cat_sales + COALESCE(ss.store_sales, 0) + COALESCE(ws.web_sales, 0)) > 0
            THEN (COALESCE(r.cat_return_amount, 0) + COALESCE(sr.store_return_amount, 0) + COALESCE(wr.web_return_amount, 0)) /
                 (s.cat_sales + COALESCE(ss.store_sales, 0) + COALESCE(ws.web_sales, 0))
            ELSE NULL
        END AS return_rate
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.d_year = r.d_year
       AND s.i_category = r.i_category
       AND s.i_brand = r.i_brand
    LEFT JOIN store_sales_agg ss
        ON s.d_year = ss.d_year
       AND s.i_category = ss.i_category
       AND s.i_brand = ss.i_brand
    LEFT JOIN store_returns_agg sr
        ON s.d_year = sr.d_year
       AND s.i_category = sr.i_category
       AND s.i_brand = sr.i_brand
    LEFT JOIN web_sales_agg ws
        ON s.d_year = ws.d_year
       AND s.i_category = ws.i_category
       AND s.i_brand = ws.i_brand
    LEFT JOIN web_returns_agg wr
        ON s.d_year = wr.d_year
       AND s.i_category = wr.i_category
       AND s.i_brand = wr.i_brand
    WHERE s.d_year IS NOT NULL
) t
ORDER BY t.d_year, total_sales DESC
LIMIT 100
