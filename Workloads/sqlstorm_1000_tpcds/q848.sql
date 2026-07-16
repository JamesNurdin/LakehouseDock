WITH catalog_sales_enh AS (
    SELECT
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        'Catalog' AS channel,
        cs.cs_quantity AS quantity,
        cs.cs_ext_sales_price AS sales_amount,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        d.d_year,
        i.i_category,
        i.i_brand
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
),
store_sales_enh AS (
    SELECT
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        'Store' AS channel,
        ss.ss_quantity AS quantity,
        ss.ss_ext_sales_price AS sales_amount,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        d.d_year,
        i.i_category,
        i.i_brand
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
),
web_sales_enh AS (
    SELECT
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        'Web' AS channel,
        ws.ws_quantity AS quantity,
        ws.ws_ext_sales_price AS sales_amount,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        d.d_year,
        i.i_category,
        i.i_brand
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
sales AS (
    SELECT * FROM catalog_sales_enh
    UNION ALL
    SELECT * FROM store_sales_enh
    UNION ALL
    SELECT * FROM web_sales_enh
),
catalog_returns_enh AS (
    SELECT
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_item_sk AS item_sk,
        'Catalog' AS channel,
        cr.cr_return_quantity AS return_quantity,
        cr.cr_return_amount AS return_amount,
        cr.cr_net_loss AS net_loss,
        d.d_year,
        i.i_category,
        i.i_brand
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
),
store_returns_enh AS (
    SELECT
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_item_sk AS item_sk,
        'Store' AS channel,
        sr.sr_return_quantity AS return_quantity,
        sr.sr_return_amt AS return_amount,
        sr.sr_net_loss AS net_loss,
        d.d_year,
        i.i_category,
        i.i_brand
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
),
web_returns_enh AS (
    SELECT
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_item_sk AS item_sk,
        'Web' AS channel,
        wr.wr_return_quantity AS return_quantity,
        wr.wr_return_amt AS return_amount,
        wr.wr_net_loss AS net_loss,
        d.d_year,
        i.i_category,
        i.i_brand
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
returns AS (
    SELECT * FROM catalog_returns_enh
    UNION ALL
    SELECT * FROM store_returns_enh
    UNION ALL
    SELECT * FROM web_returns_enh
),
sales_agg AS (
    SELECT
        d_year,
        channel,
        i_category,
        i_brand,
        SUM(sales_amount) AS total_sales_amount,
        SUM(net_paid) AS total_net_paid,
        SUM(net_profit) AS total_net_profit,
        SUM(quantity) AS total_quantity
    FROM sales
    GROUP BY d_year, channel, i_category, i_brand
),
returns_agg AS (
    SELECT
        d_year,
        channel,
        i_category,
        i_brand,
        SUM(return_amount) AS total_return_amount,
        SUM(net_loss) AS total_return_loss,
        SUM(return_quantity) AS total_return_quantity
    FROM returns
    GROUP BY d_year, channel, i_category, i_brand
),
combined AS (
    SELECT
        COALESCE(s.d_year, r.d_year) AS d_year,
        COALESCE(s.channel, r.channel) AS channel,
        COALESCE(s.i_category, r.i_category) AS i_category,
        COALESCE(s.i_brand, r.i_brand) AS i_brand,
        COALESCE(s.total_sales_amount, 0) AS total_sales_amount,
        COALESCE(s.total_net_paid, 0) AS total_net_paid,
        COALESCE(s.total_net_profit, 0) AS total_net_profit,
        COALESCE(s.total_quantity, 0) AS total_quantity,
        COALESCE(r.total_return_amount, 0) AS total_return_amount,
        COALESCE(r.total_return_loss, 0) AS total_return_loss,
        COALESCE(r.total_return_quantity, 0) AS total_return_quantity
    FROM sales_agg s
    FULL OUTER JOIN returns_agg r
        ON s.d_year = r.d_year
        AND s.channel = r.channel
        AND s.i_category = r.i_category
        AND s.i_brand = r.i_brand
),
aggregated AS (
    SELECT
        d_year,
        channel,
        i_category,
        i_brand,
        SUM(total_sales_amount) AS total_sales_amount,
        SUM(total_net_paid) AS total_net_paid,
        SUM(total_net_profit) AS total_net_profit,
        SUM(total_quantity) AS total_quantity,
        SUM(total_return_amount) AS total_return_amount,
        SUM(total_return_loss) AS total_return_loss,
        SUM(total_return_quantity) AS total_return_quantity,
        SUM(total_sales_amount) - SUM(total_return_amount) AS net_sales,
        SUM(total_net_profit) - SUM(total_return_loss) AS net_profit_after_returns
    FROM combined
    WHERE d_year BETWEEN 1998 AND 2002
    GROUP BY GROUPING SETS (
        (d_year, channel, i_category, i_brand),
        (d_year, channel, i_category),
        (d_year, channel),
        (d_year)
    )
)
SELECT
    d_year,
    channel,
    i_category,
    i_brand,
    total_sales_amount,
    total_net_paid,
    total_net_profit,
    total_quantity,
    total_return_amount,
    total_return_loss,
    total_return_quantity,
    net_sales,
    net_profit_after_returns,
    RANK() OVER (PARTITION BY d_year, channel ORDER BY net_sales DESC) AS sales_rank_by_year_channel
FROM aggregated
ORDER BY d_year, channel, net_sales DESC
