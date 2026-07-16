WITH
date_info AS (
    SELECT
        d_date_sk,
        d_date,
        d_year,
        d_month_seq,
        d_quarter_seq
    FROM date_dim
    WHERE d_year BETWEEN 1999 AND 2002
),
sales_union AS (
    SELECT
        'Catalog' AS channel,
        cs.cs_sold_date_sk AS date_sk,
        cs.cs_item_sk AS item_sk,
        cs.cs_quantity AS quantity,
        cs.cs_net_paid AS sales_amount,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amount,
        CAST(NULL AS decimal(7,2)) AS return_amount
    FROM catalog_sales cs
    UNION ALL
    SELECT
        'Store' AS channel,
        ss.ss_sold_date_sk AS date_sk,
        ss.ss_item_sk AS item_sk,
        ss.ss_quantity AS quantity,
        ss.ss_net_paid AS sales_amount,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount_amount,
        CAST(NULL AS decimal(7,2)) AS return_amount
    FROM store_sales ss
    UNION ALL
    SELECT
        'Web' AS channel,
        ws.ws_sold_date_sk AS date_sk,
        ws.ws_item_sk AS item_sk,
        ws.ws_quantity AS quantity,
        ws.ws_net_paid AS sales_amount,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount_amount,
        CAST(NULL AS decimal(7,2)) AS return_amount
    FROM web_sales ws
),
sales_agg AS (
    SELECT
        su.channel,
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        d.d_quarter_seq,
        SUM(su.sales_amount) AS total_sales,
        SUM(su.net_profit) AS total_profit,
        SUM(su.quantity) AS total_quantity,
        SUM(su.discount_amount) AS total_discount,
        COUNT(DISTINCT su.item_sk) AS distinct_items
    FROM sales_union su
    JOIN date_info d ON su.date_sk = d.d_date_sk
    GROUP BY su.channel, d.d_date_sk, d.d_date, d.d_year, d.d_month_seq, d.d_quarter_seq
),
returns_union AS (
    SELECT
        'Catalog' AS channel,
        cr.cr_returned_date_sk AS date_sk,
        cr.cr_return_amount AS return_amount,
        cr.cr_return_quantity AS return_quantity
    FROM catalog_returns cr
    UNION ALL
    SELECT
        'Store' AS channel,
        sr.sr_returned_date_sk AS date_sk,
        sr.sr_return_amt AS return_amount,
        sr.sr_return_quantity AS return_quantity
    FROM store_returns sr
    UNION ALL
    SELECT
        'Web' AS channel,
        wr.wr_returned_date_sk AS date_sk,
        wr.wr_return_amt AS return_amount,
        wr.wr_return_quantity AS return_quantity
    FROM web_returns wr
),
returns_agg AS (
    SELECT
        ru.channel,
        d.d_date_sk,
        d.d_date,
        d.d_year,
        d.d_month_seq,
        SUM(ru.return_amount) AS total_return_amount,
        SUM(ru.return_quantity) AS total_return_qty
    FROM returns_union ru
    JOIN date_info d ON ru.date_sk = d.d_date_sk
    GROUP BY ru.channel, d.d_date_sk, d.d_date, d.d_year, d.d_month_seq
),
combined AS (
    SELECT
        COALESCE(sa.channel, ra.channel) AS channel,
        COALESCE(sa.d_date, ra.d_date) AS date,
        COALESCE(sa.d_year, ra.d_year) AS year,
        COALESCE(sa.d_month_seq, ra.d_month_seq) AS month_seq,
        COALESCE(sa.total_sales, 0) AS total_sales,
        COALESCE(sa.total_profit, 0) AS total_profit,
        COALESCE(sa.total_quantity, 0) AS total_quantity,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        COALESCE(ra.total_return_qty, 0) AS total_return_qty,
        COALESCE(sa.total_discount, 0) AS total_discount,
        COALESCE(sa.distinct_items, 0) AS distinct_items
    FROM sales_agg sa
    FULL OUTER JOIN returns_agg ra
        ON sa.channel = ra.channel
        AND sa.d_date = ra.d_date
),
item_monthly_agg AS (
    SELECT
        'Catalog' AS channel,
        d.d_year AS year,
        d.d_month_seq AS month_seq,
        i.i_item_sk AS i_item_sk,
        i.i_product_name AS i_product_name,
        SUM(cs.cs_net_profit) AS profit
    FROM catalog_sales cs
    JOIN date_info d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_item_sk, i.i_product_name
    UNION ALL
    SELECT
        'Store' AS channel,
        d.d_year,
        d.d_month_seq,
        i.i_item_sk,
        i.i_product_name,
        SUM(ss.ss_net_profit) AS profit
    FROM store_sales ss
    JOIN date_info d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_item_sk, i.i_product_name
    UNION ALL
    SELECT
        'Web' AS channel,
        d.d_year,
        d.d_month_seq,
        i.i_item_sk,
        i.i_product_name,
        SUM(ws.ws_net_profit) AS profit
    FROM web_sales ws
    JOIN date_info d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY d.d_year, d.d_month_seq, i.i_item_sk, i.i_product_name
),
item_monthly_ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY channel, year, month_seq ORDER BY profit DESC) AS rn
    FROM item_monthly_agg
),
top_items AS (
    SELECT
        channel,
        year,
        month_seq,
        i_item_sk,
        i_product_name,
        profit,
        CONCAT(channel, '_', CAST(year AS VARCHAR), '_', LPAD(CAST(month_seq AS VARCHAR), 2, '0'), '_', LPAD(CAST(i_item_sk AS VARCHAR), 5, '0')) AS ranking_key
    FROM item_monthly_ranked
    WHERE rn <= 5
),
promo_stats AS (
    SELECT
        i.i_item_sk,
        i.i_product_name,
        (SELECT AVG(p.p_cost) FROM promotion p WHERE p.p_item_sk = i.i_item_sk) AS avg_promo_cost,
        (SELECT COUNT(*) FROM promotion p WHERE p.p_item_sk = i.i_item_sk) AS promo_count
    FROM item i
    WHERE i.i_current_price IS NOT NULL
)
SELECT
    c.channel,
    c.year,
    c.month_seq,
    c.date,
    ROUND(c.total_sales, 2) AS total_sales,
    ROUND(c.total_profit, 2) AS total_profit,
    ROUND(c.total_discount, 2) AS total_discount,
    c.total_quantity,
    c.total_return_amount,
    c.total_return_qty,
    ROUND(CASE WHEN c.total_sales = 0 THEN NULL ELSE c.total_profit / c.total_sales END, 4) AS profit_margin,
    t.ranking_key,
    t.i_product_name AS top_product,
    t.profit AS top_product_profit,
    COALESCE(p.avg_promo_cost, 0) AS avg_promo_cost,
    COALESCE(p.promo_count, 0) AS promo_count
FROM combined c
LEFT JOIN (
    SELECT DISTINCT
        channel,
        year,
        month_seq,
        i_item_sk,
        i_product_name,
        profit,
        ranking_key
    FROM top_items
) t
    ON c.channel = t.channel
    AND c.year = t.year
    AND c.month_seq = t.month_seq
LEFT JOIN promo_stats p
    ON t.i_item_sk = p.i_item_sk
WHERE c.year IS NOT NULL
ORDER BY c.channel, c.year, c.month_seq, c.total_sales DESC
