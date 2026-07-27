WITH base_data AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        d.d_date,
        ss.ss_item_sk,
        ss.ss_quantity,
        ss.ss_net_paid,
        ss.ss_net_profit,
        cr.cr_return_quantity,
        cr.cr_net_loss,
        wr.wr_return_quantity,
        wr.wr_return_amt_inc_tax,
        i.inv_quantity_on_hand,
        wsite.web_state,
        wsite.web_site_id
    FROM tpcds.date_dim d
    JOIN tpcds.store_sales ss ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN tpcds.catalog_returns cr ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN tpcds.web_sales ws ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN tpcds.web_returns wr ON wr.wr_returned_date_sk = d.d_date_sk
        AND wr.wr_item_sk = ws.ws_item_sk
        AND wr.wr_order_number = ws.ws_order_number
    JOIN tpcds.inventory i ON i.inv_date_sk = d.d_date_sk
    JOIN tpcds.web_site wsite ON wsite.web_site_sk = ws.ws_web_site_sk
        AND wsite.web_open_date_sk = d.d_date_sk
    WHERE d.d_year = 2001
      AND d.d_month_seq BETWEEN 1200 AND 1300
      AND i.inv_quantity_on_hand > 600
      AND wsite.web_state = 'CA'
      AND ss.ss_quantity >= 5
      AND ws.ws_net_profit > 0
),
agg_data AS (
    SELECT
        bd.d_year,
        bd.d_month_seq,
        bd.web_state,
        COUNT(DISTINCT bd.ss_item_sk) AS distinct_items_sold,
        SUM(bd.ss_net_paid) AS total_sales,
        AVG(bd.ss_net_profit) AS avg_profit,
        SUM(CASE WHEN bd.cr_net_loss > 0 THEN bd.cr_net_loss ELSE 0 END) AS total_return_loss,
        SUM(bd.wr_return_amt_inc_tax) AS total_web_return_amount,
        (SELECT AVG(inv_quantity_on_hand) FROM tpcds.inventory) AS avg_inventory_all_dates
    FROM base_data bd
    GROUP BY bd.d_year, bd.d_month_seq, bd.web_state
    HAVING COUNT(*) > 10
)
SELECT
    a.d_year,
    a.d_month_seq,
    a.web_state,
    a.distinct_items_sold,
    a.total_sales,
    a.avg_profit,
    a.total_return_loss,
    a.total_web_return_amount,
    a.avg_inventory_all_dates,
    SUM(a.total_sales) OVER (PARTITION BY a.web_state ORDER BY a.d_month_seq
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_sales_state
FROM agg_data a
ORDER BY a.d_year, a.d_month_seq
LIMIT 100
