WITH
store_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'store' AS channel,
        SUM(ss.ss_ext_sales_price) AS sales_amount,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_quantity) AS quantity_sold
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'catalog' AS channel,
        SUM(cs.cs_ext_sales_price) AS sales_amount,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_quantity) AS quantity_sold
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'web' AS channel,
        SUM(ws.ws_ext_sales_price) AS sales_amount,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_quantity) AS quantity_sold
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    JOIN web_site w ON ws.ws_web_site_sk = w.web_site_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
combined_sales AS (
    SELECT * FROM store_sales_agg
    UNION ALL
    SELECT * FROM catalog_sales_agg
    UNION ALL
    SELECT * FROM web_sales_agg
),
store_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'store' AS channel,
        SUM(sr.sr_return_amt) AS returns_amount,
        SUM(sr.sr_return_quantity) AS returns_quantity
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
catalog_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'catalog' AS channel,
        SUM(cr.cr_return_amount) AS returns_amount,
        SUM(cr.cr_return_quantity) AS returns_quantity
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
web_returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        'web' AS channel,
        SUM(wr.wr_return_amt) AS returns_amount,
        SUM(wr.wr_return_quantity) AS returns_quantity
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_year BETWEEN 2000 AND 2002
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
combined_returns AS (
    SELECT * FROM store_returns_agg
    UNION ALL
    SELECT * FROM catalog_returns_agg
    UNION ALL
    SELECT * FROM web_returns_agg
),
final_agg AS (
    SELECT
        cs.d_year,
        cs.d_month_seq,
        cs.i_category,
        cs.channel,
        cs.sales_amount,
        cs.net_profit,
        cs.quantity_sold,
        COALESCE(cr.returns_amount, 0) AS returns_amount,
        COALESCE(cr.returns_quantity, 0) AS returns_quantity,
        (cs.sales_amount - COALESCE(cr.returns_amount, 0)) AS net_sales,
        CASE WHEN cs.sales_amount = 0 THEN 0 ELSE cs.net_profit / cs.sales_amount END AS profit_margin,
        CASE WHEN cs.sales_amount = 0 THEN 0 ELSE COALESCE(cr.returns_amount, 0) / cs.sales_amount END AS return_rate
    FROM combined_sales cs
    LEFT JOIN combined_returns cr
        ON cs.d_year = cr.d_year
       AND cs.d_month_seq = cr.d_month_seq
       AND cs.i_category = cr.i_category
       AND cs.channel = cr.channel
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY d_year, d_month_seq, channel ORDER BY net_sales DESC) AS category_rank
    FROM final_agg
)
SELECT
    d_year,
    d_month_seq,
    i_category,
    channel,
    sales_amount,
    net_sales,
    net_profit,
    quantity_sold,
    returns_amount,
    returns_quantity,
    profit_margin,
    return_rate,
    category_rank
FROM ranked
WHERE category_rank <= 5
ORDER BY d_year, d_month_seq, channel, category_rank
