WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(ws.ws_net_paid) AS total_sales_net_paid,
        SUM(ws.ws_quantity) AS total_sales_qty,
        SUM(ws.ws_net_profit) AS total_sales_net_profit
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN warehouse w
        ON ws.ws_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND w.w_country = 'United States'
    GROUP BY d.d_year, d.d_month_seq, i.i_category
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        SUM(cr.cr_return_amount) AS total_return_amount,
        SUM(cr.cr_return_quantity) AS total_return_qty,
        SUM(cr.cr_net_loss) AS total_return_net_loss
    FROM catalog_returns cr
    JOIN date_dim d
        ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON cr.cr_item_sk = i.i_item_sk
    JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE d.d_year = 2001
      AND w.w_country = 'United States'
    GROUP BY d.d_year, d.d_month_seq, i.i_category
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.total_sales_net_paid,
    s.total_sales_qty,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_qty, 0) AS total_return_qty,
    s.total_sales_net_profit - COALESCE(r.total_return_net_loss, 0) AS net_profit,
    RANK() OVER (PARTITION BY s.d_year, s.d_month_seq ORDER BY (s.total_sales_net_profit - COALESCE(r.total_return_net_loss, 0)) DESC) AS profit_rank
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
   AND s.d_month_seq = r.d_month_seq
   AND s.i_category = r.i_category
ORDER BY s.d_year, s.d_month_seq, net_profit DESC
LIMIT 100
