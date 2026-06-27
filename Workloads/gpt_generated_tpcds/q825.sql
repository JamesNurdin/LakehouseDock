WITH sales_agg AS (
    SELECT
        i.i_category AS category,
        date_format(d.d_date, '%Y-%m') AS month,
        SUM(ss.ss_net_profit) AS net_profit,
        SUM(ss.ss_ext_discount_amt) AS discount_amt
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    GROUP BY i.i_category, date_format(d.d_date, '%Y-%m')
    UNION ALL
    SELECT
        i.i_category AS category,
        date_format(d.d_date, '%Y-%m') AS month,
        SUM(cs.cs_net_profit) AS net_profit,
        SUM(cs.cs_ext_discount_amt) AS discount_amt
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    GROUP BY i.i_category, date_format(d.d_date, '%Y-%m')
    UNION ALL
    SELECT
        i.i_category AS category,
        date_format(d.d_date, '%Y-%m') AS month,
        SUM(ws.ws_net_profit) AS net_profit,
        SUM(ws.ws_ext_discount_amt) AS discount_amt
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    GROUP BY i.i_category, date_format(d.d_date, '%Y-%m')
),
returns_agg AS (
    SELECT
        i.i_category AS category,
        date_format(d.d_date, '%Y-%m') AS month,
        SUM(sr.sr_net_loss) AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY i.i_category, date_format(d.d_date, '%Y-%m')
    UNION ALL
    SELECT
        i.i_category AS category,
        date_format(d.d_date, '%Y-%m') AS month,
        SUM(cr.cr_net_loss) AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    GROUP BY i.i_category, date_format(d.d_date, '%Y-%m')
    UNION ALL
    SELECT
        i.i_category AS category,
        date_format(d.d_date, '%Y-%m') AS month,
        SUM(wr.wr_net_loss) AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    GROUP BY i.i_category, date_format(d.d_date, '%Y-%m')
)
SELECT
    s.category,
    s.month,
    s.net_profit - COALESCE(r.net_loss, 0) AS net_profit_after_returns,
    s.discount_amt AS total_discount_amount,
    s.net_profit AS total_sales_net_profit,
    COALESCE(r.net_loss, 0) AS total_returns_net_loss
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.category = r.category
    AND s.month = r.month
ORDER BY net_profit_after_returns DESC
LIMIT 20
