WITH sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        ca.ca_state,
        wp.wp_type,
        SUM(ws.ws_quantity) AS total_quantity,
        SUM(ws.ws_ext_discount_amt) AS total_discount,
        SUM(ws.ws_net_profit) AS total_net_profit
    FROM web_sales ws
    JOIN date_dim d
        ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON ws.ws_bill_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2000
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category,
        ca.ca_state,
        wp.wp_type
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq,
        i.i_category,
        ca.ca_state,
        wp.wp_type,
        SUM(wr.wr_return_quantity) AS total_return_quantity,
        SUM(wr.wr_return_amt) AS total_return_amount,
        SUM(wr.wr_net_loss) AS total_net_loss
    FROM web_returns wr
    JOIN date_dim d
        ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i
        ON wr.wr_item_sk = i.i_item_sk
    JOIN customer_address ca
        ON wr.wr_refunded_addr_sk = ca.ca_address_sk
    JOIN web_page wp
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2000
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_category,
        ca.ca_state,
        wp.wp_type
)
SELECT
    s.d_year,
    s.d_month_seq,
    s.i_category,
    s.ca_state,
    s.wp_type,
    s.total_quantity,
    s.total_discount,
    s.total_net_profit,
    COALESCE(r.total_return_quantity, 0) AS total_return_quantity,
    COALESCE(r.total_return_amount, 0) AS total_return_amount,
    COALESCE(r.total_net_loss, 0) AS total_net_loss,
    s.total_net_profit - COALESCE(r.total_net_loss, 0) AS net_profit_after_returns,
    CASE
        WHEN s.total_quantity > 0 THEN s.total_discount / s.total_quantity
        ELSE 0
    END AS avg_discount_per_item
FROM sales_agg s
LEFT JOIN returns_agg r
    ON s.d_year = r.d_year
    AND s.d_month_seq = r.d_month_seq
    AND s.i_category = r.i_category
    AND s.ca_state = r.ca_state
    AND s.wp_type = r.wp_type
ORDER BY
    s.d_year,
    s.d_month_seq,
    net_profit_after_returns DESC
LIMIT 100
