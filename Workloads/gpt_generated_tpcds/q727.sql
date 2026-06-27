WITH monthly_category_ship_state AS (
    SELECT
        date_dim.d_year,
        date_dim.d_month_seq,
        item.i_category,
        ship_mode.sm_type,
        customer_address.ca_state,
        SUM(web_sales.ws_net_profit) AS total_net_profit
    FROM web_sales
    JOIN date_dim
        ON web_sales.ws_sold_date_sk = date_dim.d_date_sk
    JOIN item
        ON web_sales.ws_item_sk = item.i_item_sk
    JOIN ship_mode
        ON web_sales.ws_ship_mode_sk = ship_mode.sm_ship_mode_sk
    JOIN customer_address
        ON web_sales.ws_bill_addr_sk = customer_address.ca_address_sk
    WHERE date_dim.d_year = 2001
    GROUP BY
        date_dim.d_year,
        date_dim.d_month_seq,
        item.i_category,
        ship_mode.sm_type,
        customer_address.ca_state
)
SELECT
    d_year,
    d_month_seq,
    ca_state,
    i_category,
    sm_type,
    total_net_profit,
    RANK() OVER (PARTITION BY d_year, d_month_seq, ca_state ORDER BY total_net_profit DESC) AS profit_rank
FROM monthly_category_ship_state
ORDER BY d_year, d_month_seq, ca_state, profit_rank
