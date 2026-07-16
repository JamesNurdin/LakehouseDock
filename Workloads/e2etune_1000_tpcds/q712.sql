WITH sales_agg AS (
    SELECT
        d.d_year AS d_year,
        d.d_quarter_name AS d_quarter_name,
        i.i_category AS i_category,
        SUM(ss.ss_net_paid) AS total_sales,
        SUM(COALESCE(sr.sr_return_amt, 0)) AS total_store_returns,
        SUM(COALESCE(wr.wr_return_amt, 0)) AS total_web_returns,
        SUM(ss.ss_net_profit) AS total_net_profit,
        AVG(inv.inv_quantity_on_hand) AS avg_inventory_on_hand,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    LEFT JOIN store_returns sr ON ss.ss_ticket_number = sr.sr_ticket_number
        AND ss.ss_item_sk = sr.sr_item_sk
        AND sr.sr_returned_date_sk = d.d_date_sk
    LEFT JOIN web_returns wr ON i.i_item_sk = wr.wr_item_sk
        AND wr.wr_returned_date_sk = d.d_date_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk
        AND inv.inv_date_sk = d.d_date_sk
    JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
    WHERE cc.cc_class = 'large'
        AND cc.cc_manager = 'Bob Belcher'
        AND d.d_year BETWEEN 2001 AND 2005
        AND i.i_category IS NOT NULL
    GROUP BY d.d_year, d.d_quarter_name, i.i_category
    HAVING SUM(ss.ss_net_paid) > 100000
)
SELECT
    d_year,
    d_quarter_name,
    i_category,
    total_sales,
    total_store_returns,
    total_web_returns,
    (total_sales - total_store_returns - total_web_returns) AS net_sales,
    total_net_profit,
    avg_inventory_on_hand,
    distinct_transactions,
    RANK() OVER (PARTITION BY d_year ORDER BY (total_sales - total_store_returns - total_web_returns) DESC) AS sales_rank
FROM sales_agg
ORDER BY d_year, net_sales DESC
LIMIT 50
