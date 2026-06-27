/*
  Analytical query: brand‑month performance for the year 2002, combining sales and returns.
  - Sales are aggregated by item brand and month of the sale date.
  - Returns are aggregated by the same brand and month of the return date.
  - The final result shows quantities, amounts, discount % and net profit after accounting for returns,
    plus a ranking of profit performance.
*/
WITH sales_agg AS (
    SELECT
        i.i_brand AS brand,
        date_format(d_sales.d_date, '%Y-%m') AS sales_month,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_sales_price) AS total_sales_amount,
        SUM(ws.ws_ext_discount_amt) AS total_discount_amount,
        SUM(ws.ws_net_profit) AS total_net_profit,
        COUNT(DISTINCT ws.ws_bill_customer_sk) AS distinct_customers
    FROM web_sales ws
    JOIN date_dim d_sales ON ws.ws_sold_date_sk = d_sales.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
    WHERE d_sales.d_year = 2002
    GROUP BY i.i_brand, date_format(d_sales.d_date, '%Y-%m')
),
returns_agg AS (
    SELECT
        i.i_brand AS brand,
        date_format(d_return.d_date, '%Y-%m') AS return_month,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_net_loss) AS total_return_loss
    FROM web_returns wr
    JOIN date_dim d_return ON wr.wr_returned_date_sk = d_return.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
    WHERE d_return.d_year = 2002
    GROUP BY i.i_brand, date_format(d_return.d_date, '%Y-%m')
)
SELECT
    s.brand,
    s.sales_month,
    s.total_quantity,
    s.total_sales_amount,
    s.total_discount_amount,
    ROUND(100.0 * s.total_discount_amount / NULLIF(s.total_sales_amount, 0), 2) AS discount_pct,
    s.total_net_profit,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_net_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    RANK() OVER (ORDER BY s.total_net_profit - COALESCE(r.total_return_loss, 0) DESC) AS profit_rank,
    s.distinct_customers
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.brand = r.brand
   AND s.sales_month = r.return_month
ORDER BY net_profit_after_returns DESC
LIMIT 50
