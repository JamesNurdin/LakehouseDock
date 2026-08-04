WITH sampled_store_returns AS (
    SELECT *
    FROM store_returns
    TABLESAMPLE BERNOULLI (10)
),
sales_with_array AS (
    SELECT
        ws.*,
        ARRAY[ws_quantity, CAST(ws_ext_sales_price AS double)] AS qty_price_arr
    FROM web_sales ws
),
joined_data AS (
    SELECT
        sr.sr_returned_date_sk,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_return_tax,
        sr.sr_net_loss,
        c.c_customer_id,
        c.c_birth_year,
        r.r_reason_desc,
        s.s_store_name,
        s.s_country,
        t.t_hour,
        wp.wp_url AS sales_page_url,
        wp2.wp_url AS return_page_url,
        ws.ws_order_number,
        ws.ws_ext_list_price,
        ws.ws_ext_sales_price,
        ws.ws_quantity,
        u.qty_or_price,
        ROW_NUMBER() OVER (ORDER BY ws.ws_order_number) AS global_row_num,
        RANK() OVER (PARTITION BY s.s_country ORDER BY ws.ws_ext_list_price DESC) AS country_price_rank
    FROM sampled_store_returns sr
    JOIN time_dim t
        ON sr.sr_return_time_sk = t.t_time_sk
    JOIN customer c
        ON sr.sr_customer_sk = c.c_customer_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN reason r
        ON sr.sr_reason_sk = r.r_reason_sk
    JOIN sales_with_array ws
        ON ws.ws_sold_time_sk = t.t_time_sk
    JOIN web_page wp
        ON ws.ws_web_page_sk = wp.wp_web_page_sk
    LEFT JOIN web_returns wr
        ON wr.wr_order_number = ws.ws_order_number
        AND wr.wr_returned_time_sk = t.t_time_sk
    LEFT JOIN web_page wp2
        ON wr.wr_web_page_sk = wp2.wp_web_page_sk
    LEFT JOIN reason r_wr
        ON wr.wr_reason_sk = r_wr.r_reason_sk
    CROSS JOIN UNNEST(ws.qty_price_arr) AS u(qty_or_price)
    WHERE s.s_country = 'United States'
      AND r.r_reason_desc LIKE '%color%'
      AND c.c_birth_year BETWEEN 1970 AND 1990
      AND ws.ws_ext_list_price > (
          SELECT MAX(ws2.ws_ext_list_price)
          FROM web_sales ws2
          WHERE ws2.ws_quantity > 5
      )
      AND t.t_hour BETWEEN 9 AND 17
)
SELECT
    sr_returned_date_sk,
    sr_return_quantity,
    sr_return_amt,
    sr_return_tax,
    sr_net_loss,
    c_customer_id,
    c_birth_year,
    r_reason_desc,
    s_store_name,
    s_country,
    t_hour,
    sales_page_url,
    return_page_url,
    ws_order_number,
    ws_ext_list_price,
    ws_ext_sales_price,
    ws_quantity,
    qty_or_price,
    global_row_num,
    country_price_rank
FROM joined_data
ORDER BY global_row_num
OFFSET 10
LIMIT 100
