WITH sales AS (
    SELECT
        d.d_year,
        d.d_moy,
        ca.ca_state,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        SUM(ws.ws_net_profit) AS total_profit,
        SUM(ws.ws_quantity) AS total_quantity
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY
        d.d_year,
        d.d_moy,
        ca.ca_state
),
returns AS (
    SELECT
        d.d_year,
        d.d_moy,
        ca.ca_state,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_return_loss,
        COUNT(*) AS return_count
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_item_sk = ws.ws_item_sk
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    GROUP BY
        d.d_year,
        d.d_moy,
        ca.ca_state
)
SELECT
    s.d_year,
    s.d_moy,
    s.ca_state,
    s.total_sales,
    s.total_profit,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_return_loss, 0) AS total_return_loss,
    s.total_profit - COALESCE(r.total_return_loss, 0) AS net_profit_after_returns,
    CASE WHEN s.total_sales > 0 THEN (COALESCE(r.total_return_amount, 0) / s.total_sales) * 100 ELSE NULL END AS return_rate_pct
FROM sales s
LEFT JOIN returns r
    ON s.d_year = r.d_year
    AND s.d_moy = r.d_moy
    AND s.ca_state = r.ca_state
ORDER BY s.d_year, s.d_moy, s.ca_state
