-- Net profit per item category by month for the year 1998 across all sales channels,
-- accounting for returns as negative profit.
WITH all_transactions AS (
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        i.i_category AS category,
        ss.ss_net_profit AS profit
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '1998-01-01' AND d.d_date < DATE '1999-01-01'
    
    UNION ALL
    
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        i.i_category AS category,
        cs.cs_net_profit AS profit
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '1998-01-01' AND d.d_date < DATE '1999-01-01'
    
    UNION ALL
    
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        i.i_category AS category,
        ws.ws_net_profit AS profit
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '1998-01-01' AND d.d_date < DATE '1999-01-01'
    
    UNION ALL
    
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        i.i_category AS category,
        -cr.cr_net_loss AS profit
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '1998-01-01' AND d.d_date < DATE '1999-01-01'
    
    UNION ALL
    
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        i.i_category AS category,
        -sr.sr_net_loss AS profit
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '1998-01-01' AND d.d_date < DATE '1999-01-01'
    
    UNION ALL
    
    SELECT
        d.d_year AS year,
        d.d_month_seq AS month,
        i.i_category AS category,
        -wr.wr_net_loss AS profit
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d.d_date >= DATE '1998-01-01' AND d.d_date < DATE '1999-01-01'
)
SELECT
    year,
    month,
    category,
    sum(profit) AS total_net_profit
FROM all_transactions
GROUP BY year, month, category
ORDER BY year, month, total_net_profit DESC
