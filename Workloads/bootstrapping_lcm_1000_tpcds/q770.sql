WITH joined_data AS (
    SELECT
        cp.cp_department AS cp_department,
        cp.cp_catalog_number AS cp_catalog_number,
        cp.cp_catalog_page_number AS cp_catalog_page_number,
        cp.cp_description AS cp_description,
        cp.cp_type AS cp_type,
        d_ret.d_year AS d_year,
        d_ret.d_month_seq AS d_month_seq,
        d_ret.d_date AS return_date,
        ws.ws_item_sk AS ws_item_sk,
        ws.ws_net_profit AS ws_net_profit,
        ws.ws_quantity AS ws_quantity,
        ws.ws_sales_price AS ws_sales_price,
        ws.ws_ext_sales_price AS ws_ext_sales_price,
        cr.cr_item_sk AS cr_item_sk,
        cr.cr_net_loss AS cr_net_loss,
        cr.cr_return_quantity AS cr_return_quantity,
        cr.cr_return_amount AS cr_return_amount,
        s.s_store_name AS s_store_name,
        s.s_city AS s_city,
        s.s_state AS s_state,
        d_start.d_date AS page_start_date,
        d_end.d_date AS page_end_date,
        d_ship.d_date AS ship_date
    FROM catalog_returns cr
    JOIN catalog_page cp
        ON cr.cr_catalog_page_sk = cp.cp_catalog_page_sk
    JOIN date_dim d_ret
        ON cr.cr_returned_date_sk = d_ret.d_date_sk
    JOIN web_sales ws
        ON ws.ws_sold_date_sk = d_ret.d_date_sk
    JOIN date_dim d_ship
        ON ws.ws_ship_date_sk = d_ship.d_date_sk
    JOIN store s
        ON s.s_closed_date_sk = d_ret.d_date_sk
    LEFT JOIN date_dim d_start
        ON cp.cp_start_date_sk = d_start.d_date_sk
    LEFT JOIN date_dim d_end
        ON cp.cp_end_date_sk = d_end.d_date_sk
),
aggregated AS (
    SELECT
        cp_department,
        d_year,
        d_month_seq,
        MIN(page_start_date) AS page_start_date,
        MAX(page_end_date) AS page_end_date,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(cr_net_loss) AS total_net_loss,
        COUNT(DISTINCT ws_item_sk) AS distinct_items_sold,
        COUNT(DISTINCT cr_item_sk) AS distinct_items_returned,
        SUM(ws_quantity) AS total_quantity_sold,
        SUM(cr_return_quantity) AS total_quantity_returned,
        MIN(s_store_name) AS store_name,
        MIN(s_city) AS store_city,
        MIN(s_state) AS store_state
    FROM joined_data
    GROUP BY cp_department, d_year, d_month_seq
)
SELECT
    cp_department,
    d_year,
    d_month_seq,
    page_start_date,
    page_end_date,
    total_net_profit,
    total_net_loss,
    distinct_items_sold,
    distinct_items_returned,
    total_quantity_sold,
    total_quantity_returned,
    store_name,
    store_city,
    store_state,
    ROW_NUMBER() OVER (ORDER BY total_net_profit DESC) AS profit_rank
FROM aggregated
ORDER BY total_net_profit DESC
LIMIT 100
