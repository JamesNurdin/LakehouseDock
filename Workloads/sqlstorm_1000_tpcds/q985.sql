WITH
catalog_sales_agg AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        i.i_category AS category,
        i.i_brand AS brand,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS ext_sales_price,
        cs.cs_net_profit AS net_profit
    FROM catalog_sales cs
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
),
store_sales_agg AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        i.i_category AS category,
        i.i_brand AS brand,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS ext_sales_price,
        ss.ss_net_profit AS net_profit
    FROM store_sales ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
),
web_sales_agg AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        i.i_category AS category,
        i.i_brand AS brand,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS ext_sales_price,
        ws.ws_net_profit AS net_profit
    FROM web_sales ws
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
combined_sales AS (
    SELECT
        date_sk,
        item_sk,
        category,
        brand,
        SUM(quantity) AS total_quantity,
        SUM(ext_sales_price) AS total_sales,
        SUM(net_profit) AS total_profit
    FROM (
        SELECT * FROM catalog_sales_agg
        UNION ALL
        SELECT * FROM store_sales_agg
        UNION ALL
        SELECT * FROM web_sales_agg
    ) s
    GROUP BY date_sk, item_sk, category, brand
),
catalog_returns_agg AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        cr.cr_return_quantity AS return_qty,
        cr.cr_return_amount AS return_amt
    FROM catalog_returns cr
),
store_returns_agg AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_item_sk AS item_sk,
        sr.sr_return_quantity AS return_qty,
        sr.sr_return_amt AS return_amt
    FROM store_returns sr
),
web_returns_agg AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_item_sk AS item_sk,
        wr.wr_return_quantity AS return_qty,
        wr.wr_return_amt AS return_amt
    FROM web_returns wr
),
combined_returns AS (
    SELECT
        date_sk,
        item_sk,
        SUM(return_qty) AS total_return_qty,
        SUM(return_amt) AS total_return_amt
    FROM (
        SELECT * FROM catalog_returns_agg
        UNION ALL
        SELECT * FROM store_returns_agg
        UNION ALL
        SELECT * FROM web_returns_agg
    ) r
    GROUP BY date_sk, item_sk
),
joined AS (
    SELECT
        cs.date_sk,
        d.d_year,
        d.d_moy,
        cs.category,
        cs.brand,
        cs.total_quantity,
        cs.total_sales,
        cs.total_profit,
        COALESCE(cr.total_return_qty, 0) AS total_return_qty,
        COALESCE(cr.total_return_amt, 0) AS total_return_amt,
        (cs.total_sales - COALESCE(cr.total_return_amt, 0)) AS net_sales,
        (cs.total_profit - COALESCE(cr.total_return_amt, 0)) AS net_profit
    FROM combined_sales cs
    LEFT JOIN combined_returns cr
        ON cs.date_sk = cr.date_sk AND cs.item_sk = cr.item_sk
    JOIN date_dim d
        ON cs.date_sk = d.d_date_sk
    WHERE d.d_year BETWEEN 1999 AND 2000
)
SELECT
    d_year,
    d_moy,
    category,
    brand,
    total_quantity,
    total_sales,
    total_profit,
    total_return_qty,
    total_return_amt,
    net_sales,
    net_profit,
    ROW_NUMBER() OVER (PARTITION BY d_year, d_moy ORDER BY net_sales DESC) AS sales_rank
FROM joined
ORDER BY d_year, d_moy, sales_rank
LIMIT 100
